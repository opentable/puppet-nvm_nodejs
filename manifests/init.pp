class nvm_nodejs (
  $user,
  $version,
  $home = "/home/${user}",
) {

  Exec {
    path => [
       '/usr/local/bin',
       '/usr/bin',
       '/usr/sbin',
       '/bin',
       '/sbin',
    ],
    logoutput => on_failure,
  }

  # NOTE: supports full version numbers (x.x.x) only, otherwise node path will be wrong
  validate_re($version, '^\d+\.\d+\.\d+$',
    'Please specify a valid nodejs version, format: x.x.x (e.g. 0.8.10)')

  # node path and executable
  $NODE_PATH  = "${home}/.nvm/v${version}/bin"
  $NODE_EXEC  = "${NODE_PATH}/node"
  $NPM_EXEC   = "${NODE_PATH}/npm"
  $filename   = "node-v${version}-linux-x64"

  # dependency check
  ensure_resource('package', 'git', { ensure => installed })
  ensure_resource('package', 'curl', { ensure => installed})
  ensure_resource('package', 'make', { ensure => installed})
  
  # create nvm folder
  file { "${home}/.nvm":
    ensure      => directory,
    owner       => $user,
    group       => $user,
    mode        => '0775',
  }

  exec { 'nvm-download-node':
    command     => "wget -q http://nodejs.org/dist/v${version}/${filename}.tar.gz",
    cwd         => $home,
    user        => $user,
    provider    => shell,
    creates     => "${home}/${filename}.tar.gz"
  }

  exec { 'nvm-extract-node':
    command     => "tar -xvf ${filename}.tar.gz",
    cwd         => $home,
    user        => $user,
    provider    => shell,
    creates     => "${home}/${filename}",
    refreshonly => true
  }

  exec { 'nvm-install-node':
    command     => "mv ${filename} .nvm/v${version}",
    cwd         => $home,
    user        => $user,
    provider    => shell,
    creates     => "${home}/.nvm/v${version}",
    refreshonly => true
  }

  # sanity check
  exec { 'nodejs-check':
    command     => "${NODE_EXEC} -v",
    user        => $user,
    environment => [ "HOME=${home}" ],
    refreshonly => true,
  }
  
  # order of things
  File["${home}/.nvm"] ~> Exec['nvm-download-node']
    ~> Exec['nvm-extract-node'] ~> Exec['nvm-install-node']
    ~> Exec['nodejs-check']
}

