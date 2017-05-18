if "GRDIR" in keys(ENV)
    have_dir = length(ENV["GRDIR"]) > 0
elseif isdir(joinpath(homedir(), "gr"), "fonts")
    have_dir = true
else
    have_dir = false
    for d in ("/opt", "/usr/local", "/usr")
        if isdir(joinpath(d, "gr", "fonts"))
            have_dir = true
            break
        end
    end
end
if !have_dir
  version = v"0.24.0"
  try
    v = Pkg.installed("GR")
    if string(v)[end:end] == "+"
      version = "latest"
    end
  end
  if Sys.KERNEL == :NT
    os = :Windows
  else
    os = Sys.KERNEL
  end
  const arch = Sys.ARCH
  if os == :Linux && arch == :x86_64
    if isfile("/etc/redhat-release")
      rel = readstring(pipeline(`cat /etc/redhat-release`, `sed s/.\*release\ //`, `sed s/\ .\*//`))[1:end-1]
      if rel > "7.0"
        os = "Redhat"
      end
    elseif isfile("/etc/os-release")
      id = readstring(pipeline(`cat /etc/os-release`, `grep ^ID=`, `cut -d= -f2`))[1:end-1]
      if id in ("debian", "ubuntu")
        os = ucfirst(id)
      end
    end
  end
  tarball = "gr-$version-$os-$arch.tar.gz"
  if !isfile("downloads/$tarball")
    info("Downloading pre-compiled GR $version $os binary")
    mkpath("downloads")
    download("http://gr-framework.org/downloads/$tarball", "downloads/$tarball")
    if os == :Windows
      success(`$JULIA_HOME/7z x downloads/$tarball -y`)
      rm("downloads/$tarball")
      tarball = tarball[1:end-3]
      success(`$JULIA_HOME/7z x $tarball -y -ttar`)
      rm("$tarball")
    else
      run(`tar xzf downloads/$tarball`)
      rm("downloads/$tarball")
    end
  end
  if os == :Darwin
    app = joinpath("gr", "Applications", "GKSTerm.app")
    run(`/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f $app`)
    try
      @eval import Homebrew
      if Pkg.installed("Homebrew") != nothing
        qt = Homebrew.prefix("qt")
        path = joinpath(qt, "Frameworks")
        if isdir(path)
          for d in ("QtCore.framework", "QtGui.framework", "QtWidgets.framework")
            target = joinpath(path, d)
            link = joinpath(pwd(), "gr", "lib", d)
            rm(link, force=true)
            symlink(target, link)
          end
          println("Using Qt ", splitdir(qt)[end], " at ", qt)
        end
      end
    end
  end
end
