var os = require('os')
var fs = require('fs');
var path = require('path')
var exec = require('child_process').execSync;
function puts(error, stdout, stderr) { console.log(stdout) }

var err_code = 0;
var is_win = (os.platform() === 'win32');
var dir_script = path.dirname( process.argv[1] );
var script_array = process.argv[2].split(",");
script_array.forEach(function(script) {

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
		err_code = err_code + 1;
	}

});
process.exit(err_code);

