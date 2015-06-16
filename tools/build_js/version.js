var path = require("path");
var fs = require("fs");
var fsx = require('fs-extra');

module.exports =  (function() {
	var _file_path = path.join(__dirname, "./../../VERSION");
	var _major = 0;
	var _minor = 0;
	var _patch = 0;
	var _build = 0;
	function _getMajor() {
		module.exports.MAJOR = _major;
		return _major;
	};
	function _getMinor() {
		module.exports.MINOR = _minor;
		return _minor;
	};
	function _getPatch() {
		module.exports.PATCH = _patch;
		return _patch;
	};
	function _getBuild() {
		module.exports.BUILD = _build;
		return _build;
	};
	function _setMajor(val) {
		module.exports.MAJOR = _major = val;
	};
	function _setMinor(val) {
		module.exports.MINOR = _minor = val;
	};
	function _setPatch(val) {
		module.exports.PATCH = _patch = val;
	};
	function _setBuild(val) {
		module.exports.BUILD = _build = val;
	};
	function _incMajor() {
		module.exports.MAJOR = _major = _major + 1;
		_setMinor(0);
		_setPatch(0);
		_setBuild(0);
	};
	function _incMinor() {
		module.exports.MINOR = _minor = _minor + 1;
		_setPatch(0);
		_setBuild(0);
	};
	function _incPatch() {
		module.exports.PATCH = _patch = _patch + 1;
		_setBuild(0);
	};
	function _incBuild() {
		module.exports.BUILD = _build = _build + 1;
	};
	function _getVersion() {
		return _major + "." + _minor + "." + _patch + "." + _build;
	};
	function _setVersion(major, minor, patch, build) {
		_setMajor(parseInt(major) || 0);
		_setMinor(parseInt(minor) || 0);
		_setPatch(parseInt(patch) || 0);
		_setBuild(parseInt(build) || 0);
	};
	function _loadVersion() {
		var data = "";
		try {
			data = fs.readFileSync(_file_path, 'utf8');
		} catch(e) {
			console.log(e);
		}
		var res = data.split('.');
		_setVersion(res[0], res[1], res[2], res[3]);
	};
	function _saveVersion() {
		try {
			fsx.deleteSync(_file_path);
			fs.writeFileSync(_file_path, _getVersion(), 'utf8');
		} catch(e) {
			console.log(e);
		}
	};
	
	if(!fs.existsSync(_file_path)) _saveVersion();
	_loadVersion();

	return {
		FILE_PATH : _file_path,
		MAJOR : _getMajor(),
		MINOR : _getMinor(),
		PATCH : _getPatch(),
		BUILD : _getBuild(),
		getMajor : _getMajor,
		getMinor : _getMinor,
		getPatch : _getPatch,
		getBuild : _getBuild,	
		setMajor : _setMajor,
		setMinor : _setMinor,
		setPatch : _setPatch,
		setBuild : _setBuild,
		incMajor : _incMajor,
		incMinor : _incMinor,
		incPatch : _incPatch,
		incBuild : _incBuild,
		getVersion : _getVersion,
		loadVersion : _loadVersion,
		saveVersion : _saveVersion,
	};
})();