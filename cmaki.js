#!/usr/bin/env node
var os = require('os')
var fs = require('fs');
var path = require('path')
var exec = require('shelljs').exec;

function trim(s)
{
	return ( s || '' ).replace( /^\s+|\s+$/g, '' );
}

var is_win = (os.platform() === 'win32');
var dir_script = path.dirname( process.argv[1] );
var script = process.argv[2];

if (is_win)
{
	script_execute = path.join(dir_script, script+".cmd");
	exists = fs.existsSync(script_execute)
	caller_execute = "cmd /c "
	script_execute = script_execute.replace(/\//g, "\\");
	// console.log("detect: windows - " + os.platform());
}
else
{
	script_execute = path.join(dir_script, script+".sh");
	exists = fs.existsSync(script_execute)
	caller_execute = "bash "
	script_execute = script_execute.replace(/\\/g, "/");
	// console.log("detect: linux");
}

// console.log("caller: " + caller_execute);
// console.log("script: " + script_execute);

if(exists)
{
	var child = exec(caller_execute + script_execute, {async:true, silent:true}, function(err, stdout, stderr) {
		process.exit(err);
	});
	child.stdout.on('data', function(data) {
		console.log(trim(data));
	});
	child.stderr.on('data', function(data) {
		console.log(trim(data));
	});
}
else
{
	console.log("[error] dont exits: " + script_execute);
}

