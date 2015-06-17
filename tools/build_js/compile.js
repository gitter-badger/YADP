var cprocess = require('child_process');
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

function preprocessFile(file) {
	fsx.copySync(file, file + ".tmp");
	updateFile(file);
}

function clearPreprocessor(file) {
	fsx.deleteSync(file);
	fs.renameSync(file + ".tmp", file);
}

function emptyDir(dir) {
	try {
		fsx.removeSync(dir);
		fsx.mkdirsSync(dir);
		return true;
	} catch(e) {
		return false;
	}
}

function _compile() {
	var srcPath = path.join(__dirname, settings.PATH_SP_SRC);
	var binPath = path.join(__dirname, settings.PATH_SP_BIN);
	var relPath = path.join(__dirname, settings.PATH_SP_REL);
	var incPath = path.join(__dirname, settings.PATH_SP_INCLUDE);
	var sicPath = path.join(srcPath, "include/");
	var cmpPath = path.join(__dirname, settings.PATH_COMPILER);
	
	var srcFiles = glob.sync(srcPath + "*.sp", null);
	var incFiles = glob.sync(srcPath + "*.inc", null);
	var allFiles = srcFiles.concat(incFiles);
	var cmpFiles = [];
	
	updateVersion();
	console.log("Current Version: " + version.getVersion());
	emptyDir(binPath);
	for (var i in allFiles) {
		preprocessFile(allFiles[i]);
	}
	for (var i in srcFiles) {
		var file = srcFiles[i];
		var fileRes =  path.basename(file, '.sp') + '.smx'
		var arg = ("-i" + incPath) + " " + ("-i" + sicPath) + " " + settings.COMP_FLAGS + " " + file;
		
		var proc = cprocess.execSync(cmpPath + ' ' + arg, {cwd: binPath, encoding: 'utf8'});
		process.stdout.write(proc);
		if(fs.existsSync(srcPath + fileRes)){
			cmpFiles.push(fileRes);
		}
	}
	for (var i in cmpFiles) {
		var file = cmpFiles[i];	
		fs.renameSync(srcPath + file, binPath + file);
	}
	for (var i in allFiles) {
		clearPreprocessor(allFiles[i]);
	}
	if(srcFiles.length == cmpFiles.length && argv.publish) {
		var cpath = getReleasePath(relPath);
		for (var i in srcFiles) {
			var file = srcFiles[i];	
			fsx.copySync(file, path.join(cpath, "addons/sourcemod/scripting/")  + path.basename(file));
		}
		for (var i in cmpFiles) {
			var file = cmpFiles[i];
			fsx.copySync(binPath + file, path.join(cpath, "addons/sourcemod/plugins/")  + file);
		}
		fsx.copySync(sicPath, path.join(cpath, "addons/sourcemod/scripting/include/"));
		console.log("Created Version " + version.getVersion());
	}
}

module.exports = {
	compileProject	: _compile,
};