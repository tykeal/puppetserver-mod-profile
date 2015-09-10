class profile::hardware {

  if $::manufacturer =~ /(?i-mx:dell.*)/ {
    include ::dell
    include ::dell::openmanage
  }

}
