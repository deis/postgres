package tests

import (
	"database/sql"
	"fmt"
	"github.com/deis/deis/tests/dockercli"
	"github.com/deis/deis/tests/utils"
	"github.com/lib/pq"
	"testing"
	"time"
)

func OpenDeisDatabase(t *testing.T, host string, port string) *sql.DB {
	db, err := sql.Open("postgres", "postgres://postgres@"+host+":"+port+"/postgres?sslmode=disable&connect_timeout=4")
	if err != nil {
		t.Fatal(err)
	}
	WaitForDatabase(t, db)
	return db
}

func WaitForDatabase(t *testing.T, db *sql.DB) {
	fmt.Println("--- Waiting for pg to be ready")
	for {
		err := db.Ping()
		if err, ok := err.(*pq.Error); ok {
			if err.Code.Name() == "cannot_connect_now" {
				fmt.Println(err.Message)
				time.Sleep(1000 * time.Millisecond)
				continue
			}
			fmt.Println("ping")
			fmt.Println(err)
			t.Fatal(err)
		}
		fmt.Println("pong")
		fmt.Println("Ready")
		break
	}
}

func TryTableSelect(t *testing.T, db *sql.DB, tableName string, expectFailure bool) {
	_, err := db.Query("select * from " + tableName)

	if expectFailure {
		if err == nil {
			t.Fatal("The table should not exist")
		}
	} else {
		if err != nil {
			t.Fatal(err)
		}
	}
}

func execSql(t *testing.T, db *sql.DB, q string) {
	_, err := db.Query(q)
	if err != nil {
		t.Fatal(err)
	}
}

func TestDatabaseRecovery(t *testing.T) {
	var err error
	tag, etcdPort := utils.BuildTag(), utils.RandomPort()
	cli, stdout, _ := dockercli.NewClient()
	imageName := utils.ImagePrefix() + "database" + ":" + tag

	// start etcd container
	etcdName := "deis-etcd-" + tag
	dockercli.RunTestEtcd(t, etcdName, etcdPort)
	defer cli.CmdRm("-f", etcdName)

	// create volumes
	databaseVolume := "deis-database-data-" + tag
	defer cli.CmdRm("-f", databaseVolume)
	go func() {
		fmt.Printf("--- Creating Volume\n")
		_ = cli.CmdRm("-f", "-v", databaseVolume)
		dockercli.CreateVolume(t, cli, databaseVolume, "/var/cache/postgresql/backups")
	}()
	dockercli.WaitForLine(t, stdout, databaseVolume, true)

	// setup database container start/stop routines
	host, port := utils.HostAddress(), utils.RandomPort()
	fmt.Printf("--- Run deis/database:%s at %s:%s\n", tag, host, port)
	name := "deis-database-" + tag
	defer cli.CmdRm("-f", name)
	startDatabase := func(volumeName string) {
		_ = cli.CmdRm("-f", name)
		err = dockercli.RunContainer(cli,
			"--name", name,
			"--volumes-from", volumeName,
			"--rm",
			"-p", port+":5432",
			"-e", "ETCD_SERVICE_HOST="+host,
			"-e", "ETCD_SERVICE_PORT="+etcdPort,
			"-e", "DB_SERVICE_HOST="+host,
			"-e", "DB_SERVICE_PORT="+port,
			"-e", "BACKUP_FREQUENCY=1",
			imageName)
	}

	stopDatabase := func() {
		fmt.Println("--- Stopping data-database... ")
		if err = stdout.Close(); err != nil {
			t.Fatal("Failed to closeStdout")
		}
		_ = cli.CmdStop(name)
		fmt.Println("Done")
	}

	//ACTION

	//STEP 1: start db and wait for init to complete
	cli, stdout, _ = dockercli.NewClient()
	fmt.Printf("--- Starting database... ")
	go startDatabase(databaseVolume)
	dockercli.WaitForLine(t, stdout, "server started", true)
	fmt.Println("Done")

	db := OpenDeisDatabase(t, host, port)
	TryTableSelect(t, db, "api_foo", true)

	fmt.Println("--- Creating the table")
	execSql(t, db, "create table api_foo(t text)")

	//STEP 2: make sure we observed full backup cycle after forced checkpoint
	fmt.Println("--- Waiting for the change to be backed up... ")
	dockercli.WaitForLine(t, stdout, "backup has been completed.", true)
	fmt.Println("Done")

	stopDatabase()

	//STEP 3: start db again and assert table existence
	cli, stdout, _ = dockercli.NewClient()
	fmt.Printf("--- Starting database again... ")
	go startDatabase(databaseVolume)
	dockercli.WaitForLine(t, stdout, "server started", true)
	fmt.Println("Done")

	db = OpenDeisDatabase(t, host, port)
	TryTableSelect(t, db, "api_foo", false)
}
