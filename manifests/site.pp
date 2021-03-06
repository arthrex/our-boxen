require boxen::environment
require homebrew
require gcc

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $boxen_user,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::home}/homebrew/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::boxen_user}"
  ]
}

File {
  group => 'staff',
  owner => $boxen_user
}

Package {
  provider => homebrew,
  require  => Class['homebrew']
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => File["${boxen::config::bindir}/boxen-git-credential"],
  config   => {
    'credential.helper' => "${boxen::config::bindir}/boxen-git-credential"
  }
}

Service {
  provider => ghlaunchd
}

Homebrew::Formula <| |> -> Package <| |>

node default {
  # core modules, needed for most things
  include dnsmasq
  include git
  include hub
  include nginx

  # fail if FDE is not enabled
  if $::root_encrypted == 'no' {
    fail('Please enable full disk encryption and try again')
  }

  # node versions
  include nodejs::v0_6
  include nodejs::v0_8
  include nodejs::v0_10

  class { 'ruby::global':
    version => '2.1.0'
  }

  # common, useful packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar'
    ]:
  }

  file { "${boxen::config::srcdir}/our-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }

  include vagrant

  vagrant::box { 'dockerhost/virtualbox':
    source => 'http://vagrantboxes.footballradar.com/wheezy64.box'
  }

  include chrome
  include virtualbox
  include sublime_text_2
  include heroku
  include viscosity
  include java
  include chrome::canary

  #clone repos
  #repository {
  #  'sos':
  #    source   => 'git@git.arthrex.com:marketing/sos.git',
  #    provider => 'git',
  #}

  #setup dockbar

  include dockutil
  dockutil::item { 'Add Sublime Text 2':
      item     => "/Applications/Sublime Text 2.app",
      label    => "Sublime Text 2",
      action   => "add",
      position => 20,
  }
  dockutil::item { 'Add Google Chrome':
      item     => "/Applications/Google Chrome.app",
      label    => "",
      action   => "add",
      position => 21,
  }

  
}
