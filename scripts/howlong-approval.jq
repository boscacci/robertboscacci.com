.target == $host and .artifact == $digest and .commit == $commit and (.instruction | length > 0)
and ((.recordedAt | fromdateiso8601) as $approved
  | $approved >= ($deployed | fromdateiso8601) and $approved <= now
  and ($approved >= ($verified | fromdateiso8601) or .humanSmokeTest == "confirmed by owner"))
