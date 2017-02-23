;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; Oasiz IRCX Chat Authentication ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; VERSION  1.1.3
;; AUTHOR   Rob Hildyard
;; DATE     23.02.17
;; SITE     www.oasiz.com
;; DATA     chat.oasiz.net/chat_api_key

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Callback codes - allows developers to "hook" into this script by adding an api_callback alias

;; 1 = Loading API data
;; 2 = Successful API authcode load
;; 3 = API challenge response
;; 6 = API Data/Input error
;; 7 = API Authentication error
;; 8 = IRCX Authentication fail

;; API Auth Encryption

;hmacsha1 by Ford_Lawnmower irc.GeekShed.net #Script-Help
;Syntax hmacsha1 key message or $hmacsha1(key,message)
alias hmacsha1 {
  var %key $1, %data $2
  bset -c &key 1 $regsubex(%key,/(.)/g, $asc(\1) $chr(32))
  bset -c &data 1 $regsubex(%data,/(.)/g, $asc(\1) $chr(32))
  if ($bvar(&key,0) > 64) bset -c &key 1 $hex2chr($sha1(&key,1))
  bset -c &ipad 1 $xorall($str($+(54,$chr(32)),64),$bvar(&key,1-))
  bset -c &opad 1 $xorall($str($+(92,$chr(32)),64),$bvar(&key,1-))
  bcopy &ipad $calc($bvar(&ipad,0) + 1) &data 1 -1
  bset -c &ipad 1 $hex2chr($sha1(&ipad,1))
  bcopy &opad $calc($bvar(&opad,0) + 1) &ipad 1 -1
  bset -c &return 1 $hex2chr($sha1(&opad,1))
  noop $encode(&return, mb)
  $iif($isid,return,$iif(#,say,echo -a)) $bvar(&return, 1-).text
}

alias -l hex2chr { return $regsubex($1-,/(.{2})/g, $base(\t,16,10) $chr(32)) }

alias -l xorall {
  var %p $1, %k $2, %end $iif($regex($1,/([\d]{1,})/g) > $regex($2,/([\d]{1,})/g),$v1,$v2)
  return $regsubex($str(.,%end),/(.)/g,$+($xor($iif($gettok(%p,\n,32),$v1,0),$iif($gettok(%k,\n,32),$v1,0)),$chr(32)))
}

alias access_token {
  ;; Returns valid access token in JSON format
  ;; Use md5 because certain characters fail in URLs
  set %_oa.api_time $ctime
  return $md5($hmacsha1(%_oa.api_pass,$chr(123) $+ "timestamp": $+ %_oa.api_time $+ $chr(125)))
}

;; Set API Data

alias api {
  if ( $1 == add ) {
    ;; /API ADD <API_KEY> <API_PASSWORD>
    if ($len($2) != 36 || $len($3) != 32) { $callback(6, API Data/Input error) | return }
    set %_oa.api_key $2
    set %_oa.api_pass $3
    $callback(1, Oasiz API data set. Aquiring IRCX AUTH data..)
  }
  $api_call(1)
}

;; IRCx AUTH

alias is_oasiz {
  if (96.47.35.* iswm $server) return $true
  return $false
}

alias api_call {
  if ( $1 === 1 ) {
    set %_oa.api_call ircx_authcode
  }
  else {
    set %_oa.api_query $2
    set %_oa.api_call ircx_challenge
  }
  sockopen -e oasiz $+ $rand(000,999) www.oasiz.com 443
}

on ^*:logon:*: {
  if (!$is_oasiz) return
  if (%_oa.api_pass === $null) { $callback(6, API Data/Input error) | halt }
  .raw MODE ISIRCX
  .halt
}

raw auth:*: {
  if (!$is_oasiz) return
  if ($2 === S) {
    if ($3 === OK) {
      .raw -q AUTH GateKeeperPassport S : $+ %_oa.authcode
    }
    else {
      set %_oa.challengeType 1
      $api_call(2, $remove($3,GKSSP000000))
    }
  }
  .halt
}

raw 800:*:{
  if ($2 === 0) && ($is_oasiz) {
    .raw -q USER username hostname servername :mirc
    .raw -q AUTH GateKeeperPassport I :GKSSP000000X1A
    .halt
  }
}

alias auth_fail {
  .disconnect
  $callback(8, $1)
}

raw 910:*:{
  ;; Authentication failed
  $auth_fail(910)
  .halt
}

raw 911:*:{
  ;; Authentication suspended for this IP
  $auth_fail(911)
  .halt
}

on *:sockopen:oasiz*: {
  sockwrite -n $sockname GET /api?api_key= $+ %_oa.api_key $+ &access_token= $+ $access_token() $+ &timestamp= $+ %_oa.api_time $+ &api_call= $+ %_oa.api_call $+ &query= $+ %_oa.api_query HTTP/1.1 $+ $crlf $+ host: www.oasiz.com $+ $crlf $+ Connection: close $str($crlf,2)
}

alias callback {
  if ($isalias(oasiz.api.callback)) {
    ;; We have a callback script. Lets use it
    $oasiz.api.callback($1, $2-)
  }
  else {
    ;; No callback alias detected, echo data.
    echo -s $2-
  }
}

on *:sockread:oasiz*: {
  if ($sockerr > 0) return
  var %z | sockread %z
  while ($sockbr > 0) {
    tokenize 32 %z
    if ($regex($1-,/challenge": "(.*)"/)) { set %_oa.challengeCode $regml(1) | $iif(%_oa.challengeType == 1,.RAW -q AUTH GateKeeperPassport S :GKSSP000000 $+ $regml(1),) | $callback(3, $regml(1)) | return }
    if ($regex($1-,/authcode": "(.*)"/)) { set %_oa.authcode $regml(1) | $callback(2, $regml(1)) | return }
    if ($regex($1-,/"message": "(.*)"/)) { $callback(7, $regml(1)) | return }
    return
  }
  sockread %z
}
