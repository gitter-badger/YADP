var cprocess = require('child_process');
var glob = require("glob");
var path = require("path");
var fs = require("fs");
var fsx = require('fs-extra');
var argv = require('yargs').argv;
var moment = require('moment');
var gitrev = require('git-rev-sync');
var os = require('os');
var settings = require(path.join(__dirname, "./settings" + (argv.travis ? ".travis" : "") + ".js"));
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
	res = updatePlaceholder(res, getTagExp('debug'), (argv.debug ? "1" : "0"));
	res = updatePlaceholder(res, getTagExp('release'), (argv.release || argv.publish ? "1" : "0"));
	res = updatePlaceholder(res, getTagExp('version'), version.getVersion());
	res = updatePlaceholder(res, getTagExp('date'), moment().format('YYYY-MM-DD'));
	res = updatePlaceholder(res, getTagExp('time'), moment().format('HH:mm:ss'));
	res = updatePlaceholder(res, getTagExp('datetime'), moment().format('YYYY-MM-DD HH:mm:ss'));
	res = updatePlaceholder(res, getTagExp('version'), version.getVersion());
	res = updatePlaceholder(res, getTagExp('git-hash-short'), gitrev.short());
	res = updatePlaceholder(res, getTagExp('git-hash-long'), gitrev.long());
	res = updatePlaceholder(res, getTagExp('git-branch'), gitrev.branch());
	
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

function preprocessFile(file) {
	fsx.copySync(file, file + ".tmp");
	updateFile(file);
}

function clearPreprocessor(file) {
	try {
		fsx.deleteSync(file);
		fs.renameSync(file + ".tmp", file);
	} catch(e) {
		console.log(e);
	}
}

function emptyDir(dir) {
	try {
		fsx.removeSync(dir);
		fsx.mkdirsSync(dir);
	} catch(e) {
		console.log(e);
	}
}

function getDependencyOrigins(dep_path) {
	var dependencies = require(path.join(dep_path, "./config.js")).dependencies;
	var res = "";
	console.log();
	console.log("Loading dependencies:");
	for(var dependency in dependencies) {
		if(dependencies.hasOwnProperty(dependency)) {
			for(var dpath in dependencies[dependency]) {
				if(dpath == "path_inc" && dependencies[dependency].hasOwnProperty(dpath)) {
					if(dependencies[dependency][dpath].hasOwnProperty("org")) {
						var pth = path.join(dep_path, dependencies[dependency][dpath]["org"]);
						res += "-i" + pth + " ";
						console.log(pth);
					}
				}
			}
		}
	}
	console.log();
	return res;
}

function deployDependencies(dep_path, rel_path) {
	var dependencies = require(path.join(dep_path, "./config.js")).dependencies;
	for(var dependency in dependencies) {
		if(dependencies.hasOwnProperty(dependency)) {
			for(var dpath in dependencies[dependency]) {
				if(dependencies[dependency].hasOwnProperty(dpath)) {
					if(dependencies[dependency][dpath].hasOwnProperty("org") && dependencies[dependency][dpath].hasOwnProperty("dst")) {
						if(dependencies[dependency][dpath]["org"].trim() == "" || dependencies[dependency][dpath]["dst"].trim() == "") continue;
						var org_pth = path.join(dep_path, dependencies[dependency][dpath]["org"]);
						var dst_pth = path.join(rel_path, dependencies[dependency][dpath]["dst"]);
						fsx.copySync(org_pth, dst_pth);
					}
				}
			}
		}
	}
}

function executePreprocessor(fileArr) {
	for (var i in fileArr) {
		preprocessFile(fileArr[i]);
	}
}

function buildProject(sourceFiles, sourcePath, includePath, sourceIncludePath, dependencyPath) {
	var compiledFiles = [];
	for (var i in sourceFiles) {
		var fileRes =  path.basename(sourceFiles[i], '.sp') + '.smx';
		var arg = ("-i" + includePath) + " " + ("-i" + sourceIncludePath) + " " + getDependencyOrigins(dependencyPath) + " " + settings.COMP_FLAGS + " " + sourceFiles[i];
		var cmd = (os.platform() == 'linux' ? "" : "") + path.join(__dirname, settings.PATH_COMPILER) + ' ' + arg;
		console.log("> " + cmd);
		console.log();
		try {
			var proc = cprocess.execSync(cmd, {cwd: sourcePath, encoding: 'utf8'});
			process.stdout.write(proc);
			console.log("Compiled " + sourceFiles[i]);
		} catch(e) {
			if(e && e.stdout) process.stdout.write(e.stdout);
		}
		
		if(fs.existsSync(sourcePath + fileRes)){
			compiledFiles.push(fileRes);
		}
	}
	return compiledFiles;
}

function moveBinaries(files, sourcePath, binaryPath) {
	for (var i in files) {
		fs.renameSync(sourcePath + files[i], binaryPath + files[i]);
	}
}

function copySources(files, releasePath) {
	for (var i in files) {
		fsx.copySync(files[i], path.join(releasePath, "addons/sourcemod/scripting/")  + path.basename(files[i]));
	}
}

function copyBinaries(files, binaryPath, releasePath) {
	for (var i in files) {
		fsx.copySync(binaryPath + files[i], path.join(releasePath, "addons/sourcemod/plugins/")  + files[i]);
	}
}

function copyAdditionalFiles(releasePath, sourceIncludePath, translationPath) {
	fsx.copySync(sourceIncludePath, path.join(releasePath, "addons/sourcemod/scripting/include/"));
	fsx.copySync(translationPath, path.join(releasePath, "addons/sourcemod/translations/"));
}

function updateReleaseFiles(releasePath) {
	var relFiles = glob.sync(path.join(releasePath, "addons/") + "**/*.sp", null);
	relFiles = relFiles.concat(glob.sync(path.join(releasePath, "addons/") + "**/*.inc", null));
	for (var i in relFiles) {
		preprocessFile(relFiles[i]);
	}
}

function removeTemporaryReleaseFiles(releasePath) {
	var tmpFiles = glob.sync(path.join(releasePath, "addons/") + "**/*.tmp", null);
	for (var i in tmpFiles) {
		fsx.deleteSync(tmpFiles[i]);
	}
}

function _compile() {
	var srcPath = path.join(__dirname, settings.PATH_SP_SRC);
	var binPath = path.join(__dirname, settings.PATH_SP_BIN);
	var relPath = path.join(__dirname, settings.PATH_SP_REL);
	var depPath = path.join(__dirname, settings.PATH_SP_DEP);
	var incPath = path.join(__dirname, settings.PATH_SP_INCLUDE);
	var sicPath = path.join(srcPath, "include/");
	var tlrPath = path.join(srcPath, "translations/");
	
	var srcFiles = glob.sync(srcPath + "*.sp", null);
	var incFiles = glob.sync(sicPath + "*.inc", null);
	var allFiles = srcFiles.concat(incFiles);
	
	updateVersion();
	console.log(argv.travis ? "automated build" : "");
	console.log("Current Version: " + version.getVersion());
	emptyDir(binPath);
	executePreprocessor(allFiles);
	var cmpFiles = buildProject(srcFiles, srcPath, incPath, sicPath, depPath);
	moveBinaries(cmpFiles, srcPath, binPath);
	if(srcFiles.length == cmpFiles.length && argv.publish) {
		var cpath = path.join(relPath, version.getVersion());
		copySources(srcFiles, cpath);
		copyBinaries(cmpFiles, binPath, cpath);
		copyAdditionalFiles(cpath, sicPath, tlrPath);
		updateReleaseFiles(cpath);
		removeTemporaryReleaseFiles(cpath);
		deployDependencies(depPath, cpath);
		console.log("Created Release " + version.getVersion());
	}
	for (var i in allFiles) {
		try {
			clearPreprocessor(allFiles[i]);
		} catch(e) {
			console.log(e);
		}
	}
}

module.exports = {
	compileProject	: _compile,
};