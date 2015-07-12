var cprocess = require('child_process');
var glob = require("glob");
var path = require("path");
var fs = require("fs");
var fsx = require('fs-extra');
var argv = require('yargs').argv;
var moment = require('moment');
var gitrev = require('git-rev-sync');
var os = require('os');
var settings = require(path.join(__dirname, "./settings" + (argv.travis ? ".travis" : (os.platform() == 'linux' ? ".linux" : "")) + ".js"));
var version = require(path.join(__dirname, "./version.js"));
var util = require(path.join(__dirname, "./util.js"));

function emptyDir(dir) {
	try {
		fsx.removeSync(dir);
		fsx.mkdirsSync(dir);
	} catch(e) {
		console.log(e);
	}
}

function buildProject(sourceFiles, sourcePath, includePath, sourceIncludePath, dependencyPath) {
	var compiledFiles = [];
	for (var i in sourceFiles) {
		var fileRes =  path.basename(sourceFiles[i], '.sp') + '.smx';
		var arg = ("-i" + includePath) + " " + ("-i" + sourceIncludePath) + " " + util.getDependencyOrigins(dependencyPath) + " " + settings.COMP_FLAGS + " " + sourceFiles[i];
		var cmd = path.join(__dirname, settings.PATH_COMPILER) + ' ' + arg;
		console.log();
		try {
			var proc = cprocess.execSync(cmd, {cwd: sourcePath, encoding: 'utf8'});
			process.stdout.write(proc);
		} catch(e) {
			if(e && e.stdout) process.stdout.write(e.stdout);
			console.log(e);
			continue;
		}
		compiledFiles.push(fileRes);
	}
	return compiledFiles;
}

function moveBinaries(files, sourcePath, binaryPath) {
	for (var i in files) {
		fs.renameSync(sourcePath + files[i], binaryPath + files[i]);
	}
}

function backupFiles(base_path) {
	fsx.copySync(base_path, path.join(__dirname, "../../bak/" + path.basename(base_path)));
}

function restoreFiles(base_path) {
	var act_path = path.join(__dirname, "../../bak/" + path.basename(base_path));
	fsx.deleteSync(base_path);
	fsx.copySync(act_path, base_path);
	fsx.deleteSync(act_path);
}

function _compile() {
	var srcPath = path.join(__dirname, settings.PATH_SP_SRC);
	var binPath = path.join(__dirname, settings.PATH_SP_BIN);
	var relPath = path.join(__dirname, settings.PATH_SP_REL);
	var depPath = path.join(__dirname, settings.PATH_SP_DEP);
	var incPath = path.join(__dirname, settings.PATH_SP_INCLUDE);
	var sicPath = path.join(srcPath, "include/");
	var tlrPath = path.join(srcPath, "../translations/");
	var dirPath = path.join(__dirname, "../../addons");
	
	var srcFiles = glob.sync(srcPath + "*.sp", null);
	var incFiles = glob.sync(sicPath + "*.inc", null);
	var allFiles = srcFiles.concat(incFiles);
	
	util.updateVersion();
	console.log(argv.travis ? "automated build" : "");
	console.log("Current Version: " + version.getVersion());

	emptyDir(binPath);
	backupFiles(dirPath);
	util.preprocessFiles();

	var cmpFiles = buildProject(srcFiles, srcPath, incPath, sicPath, depPath);

	moveBinaries(cmpFiles, srcPath, binPath);
	if(srcFiles.length == cmpFiles.length) {
		if(argv.publish) {
			var cpath = path.join(relPath, version.getVersion());
			util.copySources(srcFiles, cpath);
			util.copyBinaries(cmpFiles, binPath, cpath);
			util.copyAdditionalFiles(cpath, sicPath, tlrPath);
			util.updateReleaseFiles(cpath);
			util.deployDependencies(depPath, cpath);
			console.log("Created Release " + version.getVersion());
		}
	} else {
		restoreFiles(dirPath);
		return -1;
	}
	restoreFiles(dirPath);
}

module.exports = {
	compileProject	: _compile,
};