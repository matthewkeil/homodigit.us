const child = require("child_process");
const spawn = child.spawn;
const exec = child.exec;

const runMongod = async () => {
  try {
    const flags = ["--config"];

    !!process.env.MONGO_SSL
      ? flags.push(`${__dirname}/mongod.ssl.conf`)
      : flags.push(`${__dirname}/mongod.conf`);

    console.log(
      `>>> Running command\n >>> mongod ${flags.join(
        " "
      )} \n >>> through a script\n >>>`
    );
    const mongod = spawn("mongod", flags);

    mongod.stdout.on("data", data => {
      console.log(`mongod >>> ${data}`);
    });

    mongod.stderr.on("data", data => {
      console.error(`mongod:err >>> ${data}`);
    });

    mongod.on("close", code => {
      console.log(`mongod:close >>> exited with code ${code}`);
    });

    return mongod;
  } catch (err) {
    console.error(err);
  }
};

const startMongo = async () => {
  return exec("pgrep mongod", {}, async (_, stdout) => {
    if (stdout) {
      console.error("killing mongod instance running on pid ", stdout);
      exec(`kill ${stdout}`);
      return setTimeout(() => runMongod(), 100);
    }
    return runMongod();
  });
};

module.exports = startMongo();
