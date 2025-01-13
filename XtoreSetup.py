#!/usr/bin/env python

import os, sys, site, getpass
from re import I

__help__ = """Xtore setup script :
setup : Install dependencies of Xtore.
install : Install Xtore into machine.
link : Link package and script into machine, suitable for setting up developing environment.
uninstall : Uninstall Gaimon from machine (config & data will not be removed).
"""

IS_WINDOWS = sys.platform in ['win32', 'win64']
IS_VENV = sys.prefix != sys.base_prefix

def __conform__(path) :
	isRootPath = False
	splited = path.split("/")
	if len(splited) <= 1: return path
	rootPrefix = ('etc', 'var', 'usr')
	if splited[1] in rootPrefix: isRootPath = True
	if sys.platform == 'win32':
		from pathlib import Path
		result = os.sep.join([i for i in splited if len(i)])
		if isRootPath: result = str(Path.home()) + os.sep + result
		if path[-1] == "/": result = result + os.sep
		return result
	result = "/"+("/".join([i for i in splited if len(i)]))
	if path[-1] == "/": result = result + "/"
	return result


def __link__(source, destination):
	source = __conform__(source)
	destination = __conform__(destination)
	command = f"ln -s {source} {destination}"
	if sys.platform == 'win32': command = f"mklink /D {destination} {source}"
	print(command)
	os.system(command)

class XtoreSetup :
	def __init__(self) :
		self.checkBasePath()
		self.rootPath = os.path.dirname(os.path.abspath(__file__))
		self.sitePackagesPath = ''
		for path in site.getsitepackages()[::-1]:
			if os.path.isdir(path):
				self.sitePackagesPath = path
				break
		
		self.script = [
			'xt-test',
			'xt-service',
		]

		self.configList = [
		]

		self.installPathList = [
			(f"{self.getBuildPath()}/xtore", f"{self.sitePackagesPath}/xtore"),
		]

		self.copyCommand = 'cp'
		if sys.platform == 'win32': self.copyCommand = "copy"
	
	def checkBasePath(self):
		if IS_VENV :
			self.configPath = __conform__(f'{sys.prefix}/etc')
			self.resourcePath = __conform__(f'{sys.prefix}/var')
			self.scriptPath = __conform__(f'{sys.prefix}/bin')
			if not os.path.isdir(self.configPath): os.makedirs(self.configPath)
			if not os.path.isdir(self.resourcePath): os.makedirs(self.resourcePath)
		else:
			self.configPath = '/etc'
			self.resourcePath = '/var'
			self.scriptPath = '/usr/bin'

	def operate(self, operation, platform) :
		if operation == 'setup' :
			self.setup(platform)
		elif operation == 'link' :
			self.link()
		elif operation == 'uninstall' :
			self.uninstall()
		elif operation == 'clean' :
			self.clean()
	
	def clean(self):
		os.system('rm -rfv build/*')
		for root, dirs, files in os.walk('./src'):
			for i in files:
				if i[-4:] == '.cpp':
					command = f'rm {root}/{i}'
					print(command)
					os.system(command)

	def uninstall(self):
		self.uninstallLibrary()
		self.uninstallScript()
	
	def uninstallScript(self):
		for i in self.script :
			if IS_WINDOWS: continue
			os.unlink(f"{self.scriptPath}/{i}")
		
	def uninstallLibrary(self):
		packagePath = f"{self.sitePackagesPath}/xtore"
		if os.path.isdir(packagePath): os.unlink(packagePath)

	def setup(self, platform):
		self.setupBase(platform)
		self.setupPIP()
	
	def setupBase(self, platform) :
		if 'oracle' in platform or 'centos' in platform:
			with open('requirements-centos.txt') as fd :
				content = fd.read()
			self.setupYum(content.replace("\n", " "))
		elif 'debian' in platform or 'ubuntu' in platform:
			with open('requirements-ubuntu.txt') as fd :
				content = fd.read()
			self.setupAPT(content.split("\n"))
		else :
			print("*** Error Not support for platform")
			print("*** Supported platform : debian10, ubuntu20.04, oracle")
			print("*** Example : ./setup.py setup debian10")

	def setupAPT(self, packageList) :
		command = 'apt-get install -y %s'%(" ".join(packageList))
		print(command)
		os.system(command)

	def setupPIP(self) :
		print(">>> Installing pip package.")
		with open('requirements.txt') as fd :
			content = fd.read()
		command = "pip3 install %s"%(content.replace("\n", " "))

		import platform
		subversion = int(platform.python_version().split('.')[1])
		if subversion >= 11:
			command = "pip3 install --break-system-packages %s"%(content.replace("\n", " "))
		else:
			command = "pip3 install %s"%(content.replace("\n", " "))

		print(command)
		os.system(command)
	
	def getBuildPath(self):
		buildPath = './build'
		if os.path.isdir(buildPath):
			for i in os.listdir(buildPath):
				if i[:4] == 'lib.': return os.path.abspath(f'{buildPath}/{i}')
		return None
	
	def link(self) :
		self.installConfig()
		self.linkScript()
		
		for source, destination in self.installPathList  :
			destination = __conform__(destination)
			source = __conform__(source)
			if not os.path.isdir(destination) :
				__link__(source, destination)

	def install(self) :
		print(">>> Installing Xtore.")
		self.installConfig()
		self.installScript()
		for source, destination in self.installPathList  :
			destination = __conform__(destination)
			source = __conform__(source)
			if not os.path.isdir(destination) :
				os.makedirs(destination)
			command = f"{self.copyCommand} -fR {source} {destination}"
			print(command)
			os.system(command)
	
	def installConfig(self):
		path = __conform__(f"{self.configPath}/xtore")
		if not os.path.exists(path): os.makedirs(path)
		for source, destination in self.configList :
			destinationPath = __conform__(f"{path}/{destination}")
			if not os.path.isfile(destinationPath) :
				sourcePath = __conform__(f"{self.rootPath}/config/{source}")
				command = f"{self.copyCommand} {sourcePath} {destinationPath}"
				print(command)
				os.system(command)
		
	def linkScript(self):
		for i in self.script :
			if not os.path.isfile(f"{self.scriptPath}/{i}") :
				__link__(f"{self.rootPath}/script/{i}", f"{self.scriptPath}/{i}")
	
	
if __name__ == '__main__' :
	from argparse import RawTextHelpFormatter
	import argparse
	parser = argparse.ArgumentParser(description=__help__, formatter_class=RawTextHelpFormatter)
	parser.add_argument("operation", help="Operation of setup", choices=['setup', 'install', 'link', 'uninstall', 'clean'])
	parser.add_argument("-p", "--platform", help="Platform for installation of base environment.", choices=['oracle', 'centos', 'debian', 'ubuntu'])
	option = parser.parse_args(sys.argv[1:])
	if option.platform is None : option.platform = 'ubuntu'
	setup = XtoreSetup()
	setup.operate(option.operation, option.platform)

