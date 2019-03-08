const run = require("../run-command");
const exec = require("child_process").exec;

// const startMongo = require("./mongod-start").then(() => {});

exec("pgrep mongod", {}, async (_, stdout) => {
  if (stdout) {
    console.error("killing mongod instance running on pid ", stdout);
    exec(`kill ${stdout}`);
  }

  run("mongod");

  setTimeout(() => {
    run(`mongo < ${__dirname}/create-root.mongo`).then(() =>
      exec("pgrep mongod", {}, (_, stdout) => {
        if (stdout) {
          exec(`kill ${stdout}`);
        }
      })
    );
  }, 1000);
});
