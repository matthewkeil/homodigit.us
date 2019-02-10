const util = require("util");
// import * as child from "child_process";
const exec = util.promisify(require("child_process").exec);

module.exports = async command => {
  console.warn(
    `>>> Running shell command\n>>> ${command}\n>>> using node with run-command()\n>>>`
  );

  const { stdout, stderr } = await exec(command);

  if (stderr.toString().length > 0) {
    console.error(
      `"${command}"\n>>>\n>>> An error was thrown:\n\n${stderr.toString()}\n>>>\n>>>\n`
    );
    process.exit(1);
  }

  console.warn(
    `"${command}"\n>>>\n>>> The following was output:\n\n${stdout.toString()}\n>>>\n>>>\n`
  );
};
