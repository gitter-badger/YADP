var cprocess = require('child_process');
var spawn = require('child_process').spawn;
var glob = require("glob");
var path = require("path");
var fs = require("fs");
var fsx = require('fs-extra');
var argv = require('yargs').argv;
var moment = require('moment');
var settings = require(path.join(__dirname, "./settings.js"));
var version = require(path.join(__dirname, "./version.js"));

function updatePlaceholder(fileData, id, value) {
	return fileData.replace(id, value);
}

function getTagExp(tag) {
	return new RegExp('\\$(' + tag + ')\\$', 'g');
}

function updateFile(file) {
	var data = fs.readFileSync(file, 'utf8');
			
	var res = data;
	res = updatePlaceholder(res, getTagExp('version'), version.getVersion());
	res = updatePlaceholder(res, getTagExp('date'), moment().format('YYYY-MM-DD'));
	res = updatePlaceholder(res, getTagExp('time'), moment().format('HH:mm:ss'));
	res = updatePlaceholder(res, getTagExp('datetime'), moment().format('YYYY-MM-DD HH:mm:ss'));
		
	fs.writeFileSync(file, res, 'utf8');
}

function updateVersion() {
	version.loadVersion();
	if(argv.mj) version.incMajor();
	if(argv.mn) version.incMinor();
	if(argv.pt) version.incPatch();
	if(argv.bd) version.incBuild();
	version.saveVersion();
}

function getReleasePath(base) {
	return path.join(base, version.getVersion());
}

function _compile() {
	var srcPath = path.join(__dirname, settings.PATH_SP_SRC);
	var binPath = path.join(__dirname, settings.PATH_SP_BIN);
	var relPath = path.join(__dirname, settings.PATH_SP_REL);
	var incPath = path.join(__dirname, settings.PATH_SP_INCLUDE);
	var cmpPath = path.join(__dirname, settings.PATH_COMPILER);
	glob(srcPath + "*.sp", null, function (er, files) {
		updateVersion();
		console.log("Current Version: " + version.getVersion());
		for (var i in files) {
			var file = files[i];
			var fileTmp = file + ".tmp";
			var fileRes =  path.basename(file, '.sp') + '.smx'
			var arg = ("-i" + incPath) + " " + settings.COMP_FLAGS + " " + file;
			
			fsx.copySync(file, fileTmp);
			updateFile(file);
			
			var proc = cprocess.exec(cmpPath + ' ' + arg, {cwd: binPath}, function (err, stdout, stderr) {
				if(err) console.log(err.code);
			});
			
			var ls = [];
			proc.stdout.setEncoding('utf8');
			proc.stdout.on('data', function (d) { ls.push(d); });
			proc.stdout.on('end', function () {
				fsx.deleteSync(file);
				fs.renameSync(fileTmp, file);
				if(argv.publish){
					fsx.copySync(srcPath + fileRes, path.join(getReleasePath(relPath), "addons/sourcemod/plugins/")  + fileRes);
					fsx.copySync(file, path.join(getReleasePath(relPath), "addons/sourcemod/scripting/")  + path.basename(file));
				}
				fs.renameSync(srcPath + fileRes, binPath + fileRes);
				console.log(ls.join());
			});
		}
	});
}

module.exports = {
	compileProject	: _compile,
};