class nvm_nodejs (
  $user,
  $version,
  $home = "/home/${user}",
) {

  Exec {
    path      => $::path,
    user      => $user,
    logoutput => on_failure,
  }

  # NOTE: supports full version numbers (x.x.x) only, otherwise node path will be wrong
  validate_re($version, '^\d+\.\d+\.\d+$', 'Please specify a valid nodejs version, format: x.x.x (e.g. 0.8.10)')

  $arch = $::hardwaremodel ? {
    'x86_64' => 'x64',
    'x64'    => 'x64',
    default  => 'x86',
  }

  # node path and executable
  $node_path = "${home}/.nvm/v${version}/bin"
  $node_exec = "${node_path}/node"
  $npm_exec  = "${node_path}/npm"
  $filename  = "node-v${version}-linux-${arch}"

  # # create nvm folder
  file { "${home}/.nvm":
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => '0775',
  }

  exec { 'nvm-download-node':
    command => "wget -q http://nodejs.org/dist/v${version}/${filename}.tar.gz",
    cwd     => $home,
    unless  => "test -d ${home}/.nvm/v${version}",
  }

  exec { 'nvm-extract-node':
    command     => "tar -xvf ${filename}.tar.gz",
    cwd         => $home,
    refreshonly => true,
  }

  exec { 'nvm-install-node':
    command     => "mv ${filename} .nvm/v${version}",
    cwd         => $home,
    creates     => "${home}/.nvm/v${version}",
    refreshonly => true,
  }

  exec { 'nvm-cleanup':
    command     => "rm ${filename}.tar.gz",
    cwd         => $home,
    refreshonly => true,
  }

  # sanity check
  exec { "check-node-v${version}":
    command     => "${node_exec} -v",
    refreshonly => true,
  }

  File["${home}/.nvm"] ~> Exec['nvm-download-node']
  ~> Exec['nvm-extract-node'] ~> Exec['nvm-install-node']
  ~> Exec['nvm-cleanup'] ~> Exec["check-node-v${version}"]
}
