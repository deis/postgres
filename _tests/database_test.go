package tests

import (
	"fmt"
	"testing"

	"github.com/deis/deis/tests/dockercli"
	"github.com/deis/deis/tests/utils"
)

func TestDatabase(t *testing.T) {
	var err error
	tag, etcdPort := utils.BuildTag(), utils.RandomPort()
	imageName := utils.ImagePrefix() + "database" + ":" + tag
	cli, stdout, stdoutPipe := dockercli.NewClient()

	// start etcd container
	etcdName := "deis-etcd-" + tag
	dockercli.RunTestEtcd(t, etcdName, etcdPort)
	defer cli.CmdRm("-f", etcdName)

	// run database container
	host, port := utils.HostAddress(), utils.RandomPort()
	fmt.Printf("--- Run %s at %s:%s\n", imageName, host, port)
	name := "deis-database-" + tag
	defer cli.CmdRm("-f", name)
	go func() {
		_ = cli.CmdRm("-f", name)
		err = dockercli.RunContainer(cli,
			"--name", name,
			"--rm",
			"-p", port+":5432",
			"-e", "ETCD_SERVICE_HOST="+host,
			"-e", "ETCD_SERVICE_PORT="+etcdPort,
			"-e", "DB_SERVICE_HOST="+host,
			"-e", "DB_SERVICE_PORT="+port,
			imageName)
	}()
	dockercli.PrintToStdout(t, stdout, stdoutPipe, "server started")
	if err != nil {
		t.Fatal(err)
	}
	dockercli.DeisServiceTest(t, name, port, "tcp")
}
