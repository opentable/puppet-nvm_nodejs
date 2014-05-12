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

  $arch = 'x64'

  case $::hardwaremodel {
     'x86_64': { $arch = 'x64'}
     'x64'   : { $arch = 'x64'}
     'i686'  : { $arch = 'x86'}
     'i386'  : { $arch = 'x86'}
  }

  # node path and executable
  $NODE_PATH  = "${home}/.nvm/v${version}/bin"
  $NODE_EXEC  = "${NODE_PATH}/node"
  $NPM_EXEC   = "${NODE_PATH}/npm"
  $filename   = "node-v${version}-linux-${arch}"

  # create nvm folder
  file { "${home}/.nvm":
    ensure      => directory,
    owner       => $user,
    group       => $user,
    mode        => '0775'
  }

  exec { 'nvm-download-node':
    command     => "wget -q http://nodejs.org/dist/v${version}/${filename}.tar.gz",
    cwd         => $home,
    user        => $user,
    provider    => shell,
    unless      => "test -d ${home}/.nvm/v${version}"
  }

  exec { 'nvm-extract-node':
    command     => "tar -xvf ${filename}.tar.gz",
    cwd         => $home,
    user        => $user,
    provider    => shell,
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
  
  exec { 'nvm-cleanup':
    command     => "rm ${filename}.tar.gz",
    cwd         => $home,
    user        => $user,
    provider    => shell,
    refreshonly => true
  }

  # sanity check
  exec { "check-node-v${version}":
    command     => "${NODE_EXEC} -v",
    user        => $user,
    refreshonly => true,
  }

  File["${home}/.nvm"] ~> Exec['nvm-download-node']
  ~> Exec['nvm-extract-node'] ~> Exec['nvm-install-node']
  ~> Exec['nvm-cleanup'] ~> Exec["check-node-v${version}"]

}
