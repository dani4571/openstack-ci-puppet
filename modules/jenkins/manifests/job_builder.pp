class jenkins::job_builder (
    $url,
    $username,
    $password,
) {

  package { 'python-yaml':
    ensure => "present",
  }

  package { "python-jenkins":
    ensure => latest,  # okay to use latest for pip
    provider => pip,
    require => Class[pip]
  }

  vcsrepo { "/opt/jenkins_job_builder":
    ensure => latest,
    provider => git,
    revision => "master",
    source => "https://github.com/openstack-ci/jenkins-job-builder.git",
  }

  exec { "install_jenkins_job_builder":
    command => "python setup.py install",
    cwd => "/opt/jenkins_job_builder",
    path => "/bin:/usr/bin",
    refreshonly => true,
    subscribe => Vcsrepo["/opt/jenkins_job_builder"],
  }

  file { "/etc/jenkins_jobs":
    ensure => "directory",
  }

  exec { "jenkins_jobs_update":
    command => "jenkins-jobs update /etc/jenkins_jobs/config",
    path => '/bin:/usr/bin:/usr/local/bin',
    refreshonly => true,
    require => [
      File['/etc/jenkins_jobs/jenkins_jobs.ini'],
      Package['python-jenkins'],
      Package['python-yaml']
      ]
  }

# TODO: We should put in  notify Exec['jenkins_jobs_update']
#       at some point, but that still has some problems.
  file { "/etc/jenkins_jobs/jenkins_jobs.ini":
    owner => 'jenkins',
    mode => 400,
    ensure => 'present',
    content => template('jenkins/jenkins_jobs.ini.erb'),
    require => File["/etc/jenkins_jobs"],
  }

}
