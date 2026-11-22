#
=====================================================================================
#  beat-secrets.psd1  -  FILEBEAT_PASSWORD per environment
#
=====================================================================================
#  Read by Upgrade_All_Beats.ps1 / Upgrade_Local.ps1 to CREATE the machine
env var
#  FILEBEAT_PASSWORD on a server that does not already have it. An existing
value on
#  the server is NEVER overwritten.
#
#  DO NOT COMMIT THIS FILE. Keep it beside the runner, alongside the ZIPs.
#  A SYNC-RULE file (PROJECT_NOTES section 2): keep the central/ and
individual/
#  copies identical.
#
#  An ENV with NO entry here logs 'no password for ENV' and leaves
FILEBEAT_PASSWORD
#  unset rather than setting an empty one (an empty password would make the
beat fail
#  to authenticate). Every -ENV value the runners accept has an entry below.
#
=====================================================================================
@{
    dev        = '<<password>>'
    qa         = '<<password>>'
    uat        = '<<password>>'
    stg        = '<<password>>'
    production = '<<password>>'
    demo       = '<<password>>'   # demo shares DEV's credentials (as it
does DEV's Logstash)
}
