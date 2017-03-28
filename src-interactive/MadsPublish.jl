@tryimport PkgDev

"""
Checks of package is available

$(documentfunction(ispkgavailable))
"""
function ispkgavailable(modulename::String)
	flag=false
	try
		Pkg.available(modulename)
		flag=true
	catch
		warn("Module $modulename is not available")
	end
	return flag
end

"""
Lists modules required by a module (Mads by default)

$(documentfunction(required))
"""
function required(modulename::String="Mads", filtermodule::String="")
	filename = joinpath(Pkg.dir(modulename), "REQUIRE")
	if isfile(filename)
		modules = readdlm(filename)
		if filtermodule != ""
			i = modules[:,1].==filtermodule
		else
			i = modules[:,1].!="julia"
		end
		return modules[i,:];
	else
		return [filtermodule ""];
	end
end

"""
Lists modules dependents on a module (Mads by default)

$(documentfunction(dependents))
"""
function dependents(modulename::String="Mads", filter::Bool=false)
	depmodules = Pkg.dependents(modulename)
	modules = Array{Any}((0, 2))
	for i in depmodules
		modules = [modules; [i Mads.required(i, modulename)[:,2]]]
	end
	if filter
		i = modules[:,2].!=""
		modules = modules[i,:]
	end
	return modules;
end

"""
Checkout the latest version of the Mads / Julia modules

$(documentfunction(checkout))
"""
function checkout(modulename::String=""; git::Bool=true, master::Bool=false, force::Bool=false, pull::Bool=true, required::Bool=false, all::Bool=false)
	if modulename!=""
		modulenames = [modulename]
	else
		if required
			modulenames = Mads.required()[:,1]
		elseif all
			modulenames = keys(Pkg.installed())
		else
			modulenames = madsmodules
		end
	end
	if master==true || pull==true
		git = true
	end
	if !madsgit
		git = false
	end
	for i in modulenames
		if git
			info("Checking out $(i) ...")
			cwd = pwd()
			cd(Pkg.dir(i))
			if master
				if force
					run(`git checkout -f master`)
				else
					run(`git checkout master`)
				end
			end
			if pull
				run(`git pull`)
			end
			cd(cwd)
		else
			try
				Pkg.checkout(i)
			catch
				warn("$i cannot be checked out; most probably it is dirty!")
			end
		end
	end
end

"""
Push the latest version of the Mads / Julia modules in the repo

$(documentfunction(push))
"""
function push(modulename::String="")
	if modulename!=""
		modulenames = [modulename]
	else
		modulenames = madsmodules
	end
	for i in modulenames
		info("Pushing $(i) ...")
		cwd = pwd()
		cd(Pkg.dir(i))
		run(`git push`)
		cd(cwd)
	end
end

"""
Free Mads / Julia modules

$(documentfunction(free))
"""
function free(modulename::String=""; required::Bool=false, all::Bool=false)
	if modulename!=""
		modulenames = [modulename]
	else
		if required
			modulenames = Mads.required()
		elseif all
			modulenames = keys(Pkg.installed())
		else
			modulenames = madsmodules
		end
	end
	for i in modulenames
		Pkg.free(i)
	end
end

"""
Commit the latest version of the Mads / Julia modules in the repo

$(documentfunction(commit))
"""
function commit(commitmsg::String, modulename::String="")
	if modulename!=""
		modulenames = [modulename]
	else
		modulenames = madsmodules
	end
	for i in modulenames
		info("Commiting changes in $(i) ...")
		cwd = pwd()
		cd(Pkg.dir(i))
		try
			run(`git commit -a -m $(commitmsg)`)
		catch
			warn("Nothing to commit in $(i).")
		end
		cd(cwd)
	end
end

"""
Status of the Mads modules

$(documentfunction(status))
"""
function status(; git::Bool=true, gitmore::Bool=false)
	for i in madsmodules
		Mads.status(i, git=git, gitmore=gitmore)
	end
end
function status(madsmodule::String; git::Bool=madsgit, gitmore::Bool=false)
	if git
		cwd = pwd()
		info("Git status $(madsmodule) ...")
		cd(Pkg.dir(madsmodule))
		run(`git status -s`)
		if gitmore
			info("Git ID HEAD   $(madsmodule) ...")
			run(`git rev-parse --verify HEAD`)
			info("Git ID master $(madsmodule) ...")
			run(`git rev-parse --verify master`)
		end
		cd(cwd)
	else
		originalSTDOUT = STDOUT;
		tag_flag = false
		o = ""
		try
			(outRead, outWrite) = redirect_stdout();
			Pkg.status(madsmodule)
			o = readavailable(outRead);
			close(outWrite);
			close(outRead);
			redirect_stdout(originalSTDOUT);
		catch
			redirect_stdout(originalSTDOUT);
		end
		a = ascii(String(o))
		print(a)
		if ismatch(r"(dirty)", a)
			warn("$madsmodule latest changes are not committed!")
			tag_flag = false
		elseif ismatch(r"[0-9]\+", a)
			warn("$madsmodule latest changes are not tagged!")
			tag_flag = true
		elseif ismatch(r"master", a)
			info("$madsmodule latest changes are already tagged!")
			tag_flag = false
		end
		return tag_flag
	end
end

function tag(sym::Symbol=:patch)
	for i in madsmodules
		Mads.tag(i, sym)
	end
end
function tag(madsmodule::String, sym::Symbol=:patch)
	tag_flag = Mads.status(madsmodule, git=false)
	if tag_flag
		if VERSION < v"0.5"
			Pkg.tag(madsmodule, sym)
		elseif isdefined(:PkgDev)
			PkgDev.tag(madsmodule, sym)
		else
			warn("PkgDev is missing!")
		end
		info("$madsmodule is now tagged!")
	else
		warn("$madsmodule cannot be tagged!")
	end
end

@doc """
Tag the Mads modules with a default argument `:patch`

$(documentfunction(tag))
""" tag

"""
Create web documentation files for Mads functions

$(documentfunction(create_documentation))
"""
function create_documentation()
	Documenter.makedocs(root = Pkg.dir("Mads", "docs"), doctest=false, clean=true)

	d = pwd()
	cd(Pkg.dir("Mads"))
	# run(`git pull gh gh-pages`)
	run(`mkdocs build --clean`)
	run(`mkdocs gh-deploy --clean`)
	cd(d)
	return
end