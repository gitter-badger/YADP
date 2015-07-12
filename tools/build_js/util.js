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
	return fileData.replace(getTagExp(id), value);
}

function getTagExp(tag) {
	return new RegExp('\\$(' + tag + ')\\$', 'g');
}

function _preprocessFile(file) {
	var data = fs.readFileSync(file, 'utf8');
	
	var res = data;
	res = updatePlaceholder(res, 'debug', (argv.debug ? "1" : "0"));
	res = updatePlaceholder(res, 'release', (argv.release || argv.publish ? "1" : "0"));
	res = updatePlaceholder(res, 'version', version.getVersion());
	res = updatePlaceholder(res, 'date', moment().format('YYYY-MM-DD'));
	res = updatePlaceholder(res, 'time', moment().format('HH:mm:ss'));
	res = updatePlaceholder(res, 'datetime', moment().format('YYYY-MM-DD HH:mm:ss'));
	res = updatePlaceholder(res, 'version', version.getVersion());
	res = updatePlaceholder(res, 'git-hash-short', gitrev.short());
	res = updatePlaceholder(res, 'git-hash-long', gitrev.long());
	res = updatePlaceholder(res, 'git-branch', gitrev.branch());
	
	fs.writeFileSync(file, res, 'utf8');
}


function _copySources(files, releasePath) {
	for (var i in files) {
		fsx.copySync(files[i], path.join(releasePath, "addons/sourcemod/scripting/")  + path.basename(files[i]));
	}
}


function _copyBinaries(files, binaryPath, releasePath) {
	for (var i in files) {
		fsx.copySync(binaryPath + files[i], path.join(releasePath, "addons/sourcemod/plugins/")  + files[i]);
	}
}

function _copyAdditionalFiles(releasePath, sourceIncludePath, translationPath) {
	fsx.copySync(sourceIncludePath, path.join(releasePath, "addons/sourcemod/scripting/include/"));
	fsx.copySync(translationPath, path.join(releasePath, "addons/sourcemod/translations/"));
}

function _updateReleaseFiles(releasePath) {
	var relFiles = glob.sync(path.join(releasePath, "addons/") + "**/*.sp", null);
	relFiles = relFiles.concat(glob.sync(path.join(releasePath, "addons/") + "**/*.inc", null));
	for (var i in relFiles) {
		_preprocessFile(relFiles[i]);
	}
}

function _getDependencyOrigins(dep_path) {
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

function _deployDependencies(dep_path, rel_path) {
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

function _preprocessFiles() {
	var srcPath = path.join(__dirname, settings.PATH_SP_SRC);
	var sicPath = path.join(srcPath, "include/");
	var srcFiles = glob.sync(srcPath + "*.sp", null);
	var incFiles = glob.sync(sicPath + "*.inc", null);
	var allFiles = srcFiles.concat(incFiles);
	
	try {
		for (var i = allFiles.length - 1; i >= 0; i--) {
			_preprocessFile(allFiles[i]);
		};
		return 0;
	} catch(e) {
		console.log(e);
		return 1;
	}
}

function _updateVersion() {
	version.loadVersion();
	if(argv.mj) version.incMajor();
	if(argv.mn) version.incMinor();
	if(argv.pt) version.incPatch();
	if(argv.bd) version.incBuild();
	version.saveVersion();
}

module.exports = {
	preprocessFile			: _preprocessFile,
	copySources				: _copySources,
	copyBinaries			: _copyBinaries,
	copyAdditionalFiles		: _copyAdditionalFiles,
	updateReleaseFiles		: _updateReleaseFiles,
	getDependencyOrigins	: _getDependencyOrigins,
	deployDependencies		: _deployDependencies,
	deployDependencies		: _deployDependencies,
	preprocessFiles			: _preprocessFiles,
	updateVersion			: _updateVersion,
};