;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Oasiz IRCX Oper EVENTS ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; VERSION  1.0
;; AUTHOR   Rob Hildyard
;; DATE     02.10.16
;; SITE     www.oasiz.com

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

raw event:*: {
  haltdef
  if ($2-3 == SOCKET ACCEPT) return
  if ($2-3 == SOCKET CLOSE) return
  if ($4 == !@GateKeeper) return
  if (!@Events) window -bvkl @Events
  aline -hpl 2 @Events $asctime(dd/mm HH:nn:ss) - $2-
  if (%_oa.options.eventscroll) {
    sline -l @Events $line(@Events,0)
  }
}

menu @Events {
  Options
  .$submenu($ev.op($1))
  $iif(($chr(37) $+ # isin $1) && (DESTROY !isin $1),$style(0),$style(2)) Channel
  .$submenu($ev.ch($1))
  $iif((@ isin $1),$style(0),$style(2)) User
  .$submenu($ev.us($1))
}

alias ev.op {
  if ($1 == 1) { return $iif(%_oa.options.eventscroll,$style(1),$style(4)) Auto Scroll:$togglescroll() }
}

alias togglescroll {
  if ( %_oa.options.eventscroll ) {
    unset %_oa.options.eventscroll
  }
  else {
    set %_oa.options.eventscroll 1 
  }
}

alias ev.us {
  $event.setstuff()
  if ($1 == 1) { return $iif(%_oa.event.user.nick != $null,$style(0),$style(2)) WHOIS/PUID - %_oa.event.user.nick :$oper.whoispuid(%_oa.event.user.nick) }
  if ($1 == 2) { return $iif(%_oa.event.user.ip != $null,$style(0),$style(2)) DNS:/DNS %_oa.event.user.ip }
  if ($1 == 3) { return $iif(%_oa.event.user.ip != $null,$style(0),$style(2)) Duplicate IP match:.RAW WHO %_oa.event.user.ipmask }
  if ($1 == 4) { return $iif(%_oa.event.user.ip != $null,$style(0),$style(2)) Partial IP match:.RAW WHO @ $+ $maskIP(%_oa.event.user.ip) }
  if ($1 == 5) { return - }
  if ($1 == 6) { return $iif(%_oa.event.user.nick != $null,$style(0),$style(2)) Kill nick (no ban):$iif($input(Kill this nick?,yi,Confirmation),$oper.kill(%_oa.event.user.nick)) }
  if ($1 == 7) { return $iif(%_oa.event.user.nick != $null,$style(0),$style(2)) Kill nick (1 hour):$iif($input(Kill/ban this nick?,yi,Confirmation),$oper.kill(%_oa.event.user.nick,60)) }
  if ($1 == 8) { return $iif(%_oa.event.user.nick != $null,$style(0),$style(2)) Kill nick (24 hours):$iif($input(Kill/ban this nick?,yi,Confirmation),$oper.kill(%_oa.event.user.nick,1440)) }
  if ($1 == 9) { return $iif(%_oa.event.user.nick != $null,$style(0),$style(2)) Kill/ban nick (Invalid nick):$iif($input(Kill/ban this nick?,yi,Confirmation),$oper.kill(%_oa.event.user.nick,0,Banned nickname)) }
  if ($1 == 10) { return - }
  if ($1 == 11) { return $iif(%_oa.event.user.gate != $null,$style(0),$style(2)) Kill gate (no ban):$iif($input(Kill this gate?,yi,Confirmation),$oper.kill(%_oa.event.user.gate)) }
  if ($1 == 12) { return $iif(%_oa.event.user.gate != $null,$style(0),$style(2)) Kill gate (1 hour):$iif($input(Kill/ban this gate?,yi,Confirmation),$oper.kill(%_oa.event.user.gate,60)) }
  if ($1 == 13) { return $iif(%_oa.event.user.gate != $null,$style(0),$style(2)) Kill gate (24 hours):$iif($input(Kill/ban this gate?,yi,Confirmation),$oper.kill(%_oa.event.user.gate,1440)) }
  if ($1 == 14) { return - }
  if ($1 == 15) { return $iif(%_oa.event.user.ip != $null,$style(0),$style(2)) Kill IP (no ban):$iif($input(Kill IP?,yi,Confirmation),$oper.kill(%_oa.event.user.ip)) }
  if ($1 == 16) { return $iif(%_oa.event.user.ip != $null,$style(0),$style(2)) Kill/ban IP (1 hour):$iif($input(Kill/ban this IP?,yi,Confirmation),$oper.kill(%_oa.event.user.ip,60)) }
  if ($1 == 17) { return $iif(%_oa.event.user.ip != $null,$style(0),$style(2)) Kill/ban IP (24 hours):$iif($input(Kill/ban this IP?,yi,Confirmation),$oper.kill(%_oa.event.user.ip,1440)) }
  if ($1 == 18) { return - }
  if ($1 == 19) { return $iif(%_oa.event.user.nick != $null,$style(0),$style(2)) Gag user:$iif($input(Gag user?,yi,Confirmation),.RAW MODE %_oa.event.user.nick +z ) }
  if ($1 == 20) { return $iif(%_oa.event.user.nick != $null,$style(0),$style(2)) Un-gag user:$iif($input(Un-gag user?,yi,Confirmation),.RAW MODE %_oa.event.user.nick -z ) }
}

alias ev.status {
  /window -a "status window"
}

alias ev.ch {
  $event.setstuff()
  var %c $chr(37) $+ _oa.event.channel
  if ($1 == 1) { return %c properties:.RAW PROP %c * | .RAW WHO Rob }
  if ($1 == 2) { return Topic reset (w/o join):$iif($input(Reset channel topic for %c ?,yi,Confirmation),.RAW PROP %c TOPIC :) }
  if ($1 == 3) { return Topic reset (violation msg):$iif($input(Reset channel topic for %c ?,yi,Confirmation),$oper.topicreset(%_oa.event.channel)) }
  if ($1 == 4) { return Close channel:$iif($input(Close channel %c ?,yi,Confirmation),$oper.channelkill(%_oa.event.channel)) }
  if ($1 == 5) { return Kill channel:$iif($input(Kill channel %c ?,yi,Confirmation),.RAW KILL %c ) }
  if ($1 == 6) { return View access list:accesslist %c }
  if ($1 == 7) { return Channel users (WHO):.RAW WHO %c }
  if ($1 == 8) { return Channel users (NAMES):.RAW NAMES %c }
}

alias oper.kill {
  if ($2 || $2 == 0) {
    .RAW ACCESS $ ADD DENY $1 $2 : $+ ( $+ $me $+ ) $iif($3,$3)
  }
  .RAW KILL $1 : $+ $iif($3,$3,Violation of the Oasiz Code of Conduct)
}

alias oper.whoispuid {
  .RAW WHOIS $1
  .RAW PROP $1 PUID
}

alias oper.topicreset {
  .RAW ACCESS $1 ADD OWNER @snd 0
  .RAW JOIN $1
  .RAW PROP $1 TOPIC :%
  .RAW PRIVMSG $1 :Hi, I assist in running this network. This room topic contains words or references to subjects that are in violation of the Oasiz Code of Conduct and is being changed. For more information please visit http://groups.oasiz.net/conduct?pgmarket=en-us
  .RAW PART $1
}

alias oper.channelkill {
  set %_oa.closechannel $1
  .RAW PROP $1 ACCOUNT OASIZ
  .RAW ACCESS $1 CLEAR
  .RAW ACCESS $1 ADD DENY *@*
  .RAW ACCESS $1 ADD OWNER @snd 0
  .RAW JOIN $1
  .RAW MODE $1 +hmtinwWl 1
  .RAW WHO $1
}

raw 352:*: {
  if (%_oa.closechannel == $2) {
    if ('* !iswm $6) {
      .RAW MODE $2 -qov $6 $6 $6
      .RAW PROP $2 OWNERKEY $rand(100000,999999)
      .RAW PROP $2 HOSTKEY $rand(100000,999999)
    }
  }
}

raw 315:*: {
  if (%_oa.closechannel == $2) {
    unset %_oa.closechannel
    .RAW PROP $2 TOPIC :Closed for Violation of the Oasiz Code of Conduct - $me
    .RAW PRIVMSG $2 :Hi, I assist in running this network. This room is being closed for a violation of the Oasiz Code of Conduct. For more information you can follow this link. http://groups.oasiz.net/conduct?pgmarket=en-us
    .RAW PART $2
  }
}

alias event.setipdata {
  tokenize 58 $1
  set %_oa.event.user.ip $1
  set %_oa.event.user.ipmask *@ $+ $1
}

;; Currently unused. Returns 127.0.0.*
alias maskIP return $puttok($1, *, 4-, 46)

alias event.setnickmaskdata {
  tokenize 33 $1
  set %_oa.event.user.nick $1

  tokenize 64 $2
  set %_oa.event.user.gate *! $+ $1 $+ @*
}

alias event.setstuff {
  var %a = $sline(@Events,1)
  tokenize 32 %a

  if  ( $4 == CHANNEL ) {
    if ( $5 == CREATE ) {
      set %_oa.event.channel $6
      $event.setnickmaskdata($8)
      $event.setipdata($9)
    }
    elseif ( $5 == TOPIC ) {
      set %_oa.event.channel $6
      $event.setnickmaskdata($7)
      $event.setipdata($9)  
    }
    elseif ( $5 == DESTROY ) {
      set %_oa.event.channel $6
      unset %_oa.event.user.nick
      unset %_oa.event.user.gate
      unset %_oa.event.user.ip
      unset %_oa.event.user.ipmask
    }
  }
  if  ( $4 == MEMBER ) {
    if  ( $5 == KICK ) {
      set %_oa.event.channel $7
      $event.setnickmaskdata($6)
      unset %_oa.event.user.ip
      unset %_oa.event.user.ipmask
    }
    else {
      set %_oa.event.channel $6
      $event.setnickmaskdata($7)
      $event.setipdata($8)
    }
  }
  if  ( $4 == SOCKET ) {
    unset %_oa.event.channel
    unset %_oa.event.user.nick
    unset %_oa.event.user.gate
    $event.setipdata($6)
  }
  if  ( $4 == USER ) {
    unset %_oa.event.channel
    $event.setnickmaskdata($6)
    $event.setipdata($7)
  }
}
