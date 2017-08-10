var os = require('os')
var fs = require('fs');
var path = require('path')
var exec = require('child_process').exec;
function puts(error, stdout, stderr) { console.log(stdout) }

script = process.argv[2];
dir_script = path.dirname( process.argv[1] );
var is_win = (os.platform() === 'win32');
if (is_win)
{
	script_execute = path.join(dir_script, script+".cmd");
	exists = fs.existsSync(script_execute)
	script_execute = "call " + script_execute.replace(/\//g, "\\");
}
else
{
	script_execute = path.join(dir_script, script+".sh");
	exists = fs.existsSync(script_execute)
	script_execute = "bash " + script_execute.replace(/\\/g, "/");
}

if(exists)
{
	console.log("running: " + script_execute);
	exec(script_execute, puts);
}
else
{
	console.log("[error] dont exits: " + script_execute);
}

