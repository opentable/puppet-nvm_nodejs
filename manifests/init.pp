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

  # dependency check
  ensure_resource('package', 'git', { ensure => installed })
  ensure_resource('package', 'curl', { ensure => installed})
  ensure_resource('package', 'make', { ensure => installed})
  
  # create nvm folder
  file { "${home}/.nvm":
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => '0775',
  }

  exec { 'nvm-download-node':
    command     => "wget -q0 http://nodejs.org/dist/v${version}/node-v${version}-linux-x64.tar.gz",
    # http://nodejs.org/dist/v0.10.28/node-v0.10.28-linux-x64.tar.gz
    cwd         => $home,
    user        => $user,
    unless      => "test -e ${home}/.nvm/v${version}/bin/node",
    provider    => shell,
    creates     => "node-v${version}-linux-x64.tar.gz"
    #environment => [ "HOME=/${home}", "NVM_DIR=${home}/.nvm" ],
  }

  exec { 'nvm-install-node':
    command     => "tar -xvf node-v${version}-linux-x64.tar.gz && mv node-v${version}-linux-x64.tar.gz .nvm/v${version}",
    cwd         => $home,
    user        => $user,
    unless      => "test -e ${home}/.nvm/v${version}/bin/node",
    provider    => shell,
    creates     => ".nvm/v${version}"
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
    ~>Exec['nvm-install-node']~>Exec['nodejs-check']
}

