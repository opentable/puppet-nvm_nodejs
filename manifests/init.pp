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
  ensure_resource('user', $user, { 
                                   ensure     => present,
                                   shell      => '/bin/bash',
                                   home       => $home,
                                   managehome => true,
                                 });
  
  # install via script
  exec { 'nvm-install-script':
    command     => 'curl https://raw.github.com/creationix/nvm/master/install.sh | sh',
    cwd         => $home,
    user        => $user,
    creates     => "${home}/.nvm/nvm.sh",
    environment => [ "HOME=${home}" ],
    refreshonly => true,
  }
  
  exec { 'nvm-install-node':
    command     => ". ${home}/.nvm/nvm.sh && nvm install ${version}",
    cwd         => $home,
    user        => $user,
    unless      => "test -e ${home}/.nvm/v${version}/bin/node",
    provider    => shell,
    environment => [ "HOME=/${home}", "NVM_DIR=${home}/.nvm" ],
    refreshonly => true,
  }

  # sanity check
  exec { 'nodejs-check':
    command     => "${NODE_EXEC} -v",
    user        => $user,
    environment => [ "HOME=${home}" ],
    refreshonly => true,
  }
  
  # order of things
  Exec['nvm-install-script']
    ~>Exec['nvm-install-node']~>Exec['nodejs-check']
}

