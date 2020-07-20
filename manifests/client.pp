# Install FreeRADIUS clients (WISMs or testing servers)
define freeradius::client (
  String $secret,
  Optional[String] $shortname                        = $title,
  Optional[String] $ip                               = undef,
  Optional[String] $ip6                              = undef,
  Optional[Enum['*', 'udp', 'tcp']] $proto           = undef,
  Freeradius::Boolean $require_message_authenticator = 'no',
  Optional[String] $virtual_server                   = undef,
  Optional[Enum['cisco', 'computone', 'livingston', 'juniper', 'max40xx', 'multitech', 'netserver', 'pathras', 'patton', 'portslave', 'tc', 'usrhiper', 'other']] $nastype = undef,
  Optional[String] $login                            = undef,
  Optional[String] $password                         = undef,
  Optional[String] $coa_server                       = undef,
  Optional[String] $response_window                  = undef,
  Optional[Integer] $max_connections                 = undef,
  Optional[Integer] $lifetime                        = undef,
  Optional[Integer] $idle_timeout                    = undef,
  Optional[String] $redirect                         = undef,
  Optional[Integer] $port                            = undef,
  Optional[String] $srcip                            = undef,
  Boolean $firewall                                  = false,
  Freeradius::Ensure $ensure                         = present,
  Array $attributes                                  = [],
  Optional[String] $huntgroups                       = undef,
) {
  $fr_package  = $::freeradius::params::fr_package
  $fr_service  = $::freeradius::params::fr_service
  $fr_basepath = $::freeradius::params::fr_basepath
  $fr_group    = $::freeradius::params::fr_group

  file { "${fr_basepath}/clients.d/${shortname}.conf":
    ensure  => $ensure,
    mode    => '0640',
    owner   => 'root',
    group   => $fr_group,
    content => template('freeradius/client.conf.erb'),
    require => [File["${fr_basepath}/clients.d"], Group[$fr_group]],
    notify  => Service[$fr_service],
  }

  if ($firewall and $ensure == 'present') {
    if $port {
      if $ip {
        firewall { "100 ${shortname} ${port} v4":
          proto  => 'udp',
          dport  => $port,
          action => 'accept',
          source => $ip,
        }
      } elsif $ip6 {
        firewall { "100 ${shortname} ${port} v6":
          proto    => 'udp',
          dport    => $port,
          action   => 'accept',
          provider => 'ip6tables',
          source   => $ip6,
        }
      }
    } else {
      fail('Must specify $port if you specify $firewall')
    }
  }

  if $huntgroups {
    $huntgroups.each |$index, $huntgroup| {
      freeradius::huntgroup { "huntgroup.client.${shortname}.${index}":
        * => $huntgroup
      }
    }
  }
}
