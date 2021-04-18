;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; Oasiz IRCX API Auth Tool ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; VERSION  2.1
;; AUTHOR   Rob Hildyard
;; DATE     18.04.21
;; SITE     www.oasiz.com

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; IMPORTANT: This script requires oasiz.auth.mrc : http://oasiz.co/c

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menu status {
  Oasiz API Auth: if (!$dialog(oasiz)) dialog -m oasiz.api oasiz.api
}

dialog oasiz.api {
  ;; ID , LEFT, TOP, WIDTH, HEIGHT
  title "Oasiz IRCX Auth Tool v2.1"
  size -1 -1 123 147
  option dbu

  text "API Information:", 42, 6 4 40 8, left
  link "click here", 812, 47 4 60 8

  list 1,5 15 112 45

  text "Last Updated:", 10, 6 60 40 8, left
  text "N/A", 45, 45 60 75 8, left

  button "Add", 346, 5 70 36 11,
  button "Delete", 365, 43 70 36 11,
  button "Update", 8, 82 70 36 11,

  text "Server:", 100, 6 87 35 8, left
  check "Main", 110, 27 87 23 8,
  check "Groups", 130, 50 87 26 8,
  button "Connect", 34, 82 85 36 11,

  box "Status", 4, 6 98 112 33, read multi left
  edit -, 44, 11 107 102 19, read multi left
  text "Copyright © 2015", 9, 24 134 46 8, left
  link "Oasiz", 12, 70 134 30 8
}

on *:dialog:oasiz.api:init:*: {
  ;; Server check boxes
  if ( $readini(oasiz.api.ini,n,settings,s) === M ) { did -c $dname 110 }
  if ( $readini(oasiz.api.ini,n,settings,s) === G ) { did -c $dname 130 }
  if ( $readini(oasiz.api.ini,n,settings,s) === B ) { did -c $dname 110 | did -c $dname 130 }
  var %dolist = $oasiz.authtool.apidata(list)
}

on *:dialog:oasiz.api:sclick:1: {
  ;; Selecting account API in list
  var %a = $oasiz.authtool.apidata(match, $did($dname,1).seltext)
  if ( %a !== $null ) {
    ;; enable "update/delete" button
    did -e $dname 8 | did -e $dname 365
    writeini -n oasiz.api.ini settings current_api %a
    %_oa.authcode = $readini(oasiz.api.ini,n,%a,a)
    $oasiz.authtool.lastupdated($oasiz.authtool.apidata(match, $did($dname,1).seltext))
  }
  var %checkbtn = $oasiz.authtool.checkbutton
}

;;; Add new account API data
on *:dialog:oasiz.api:sclick:346: {
  var %n = $$?="Step 1 of 3: Enter a(ny) name/reference for this account.", %k = $$?="Step 2 of 3: Enter API key:", %p = $$?*="Step 3 of 3: Enter API password:"
  ;; Validate data
  var %a = $iif( $readini(oasiz.api.ini,n,%k,k), added, updated )
  if ( $len(%k) != 36 || $len(%p) != 32 ) { $oasiz.authtool.msg( Input error: Invalid API key/password detected ) | return }
  ;; Looks like we made it. Let's get it updated..
  writeini -n oasiz.api.ini %k n %n
  writeini -n oasiz.api.ini %k k %k
  writeini -n oasiz.api.ini %k p %p
  writeini -n oasiz.api.ini %k a 0
  writeini -n oasiz.api.ini %k u 0
  $oasiz.authtool.msg( %a )
  writeini -n oasiz.api.ini settings current_api %k
  $oasiz.authtool.apidata(list)
  $oasiz.authtool.update
}

;;; Delete account API data
on *:dialog:oasiz.api:sclick:365: {
  if ($?!="Are you sure you want to remove this entry?" === $true) {
    remini oasiz.api.ini $oasiz.authtool.apidata(match, $did($dname,1).seltext)
    ;; Update/refresh list
    $oasiz.authtool.apidata(list)
  }
}

;;; Update account API data
on *:dialog:oasiz.api:sclick:8: {
  $oasiz.authtool.update
}

;;; Server choice (main)
on *:dialog:oasiz.api:sclick:110: {
  $oasiz.authtool.setserver
}

;;; Server choice (groups)
on *:dialog:oasiz.api:sclick:130: {
  $oasiz.authtool.setserver
}

;;; connect button
on *:dialog:oasiz.api:sclick:34: {
  $oasiz.authtool.connect
  dialog -x oasiz.api
}

;; URLs
on *:dialog:oasiz.api:sclick:12: { url -an http://www.oasiz.com }
on *:dialog:oasiz.api:sclick:812: { url -an http://chat.oasiz.net/chat_api_key }

;; Checks if connect button needs to be enabled/disabled
alias oasiz.authtool.checkbutton {
  ;; Enable "connect" button if: we have an account selected, we've updated it, we have a server selected
  if ( ( $did(oasiz.api,1).seltext !== $null && $readini(oasiz.api.ini,n,$oasiz.authtool.apidata(match, $did($dname,1).seltext),u) !== 0 ) && ( $did(oasiz.api,110).state === 1 || $did(oasiz.api,130).state === 1) ) {
    did -e oasiz.api 34
    return 1
  }
  else {
    did -b oasiz.api 34
    return 0
  }
}

alias oasiz.authtool.msg {
  if (!$dialog(oasiz.api)) { $oasiz.api.statusprint(7,$1-) | return }
  did -r oasiz.api 44
  did -a oasiz.api 44 $1-
}

;; Last Updated
alias oasiz.authtool.lastupdated {
  did -r oasiz.api 45
  var %t = $readini(oasiz.api.ini,n,$1,u)
  did -a oasiz.api 45 $iif($1 === reset,N/A, $iif(%t != 0, %t, N/A))
}

alias oasiz.authtool.update {
  ;; Disable "add/delete/connect/update" buttons whilst we update
  did -b oasiz.api 346 | did -b oasiz.api 365 | did -b oasiz.api 8 | did -b oasiz.api 34
  $oasiz.authtool.api.update
}

alias oasiz.authtool.apidata {
  ;; Reset API data list
  if ( $1 === list ) {
    did -r oasiz.api 1
  }
  var %api_keys = 0, %x = 0, %c = 0, %s = 0
  while ( %x <= $ini(oasiz.api.ini,0) ) {
    if ( $len($ini(oasiz.api.ini,%x)) === 36 ) {
      if (%s === 0) { %s = $ini(oasiz.api.ini,%x) }
      if ( $1 === list ) {
        if ( $ini(oasiz.api.ini,%x) === $readini(oasiz.api.ini, n, settings, current_api) ) {
          %c = %x
          %s = $ini(oasiz.api.ini,%x)
        }
        did -a oasiz.api 1 $readini(oasiz.api.ini, n, $ini(oasiz.api.ini,%x), n)
      }
      if ( $1 === match ) {
        if ( $readini(oasiz.api.ini, n, $ini(oasiz.api.ini,%x), n) === $2- ) {
          return $ini(oasiz.api.ini,%x)
        }
      }
      inc %api_keys
    }
    inc %x
  }
  ;; Return null if no match found
  if ( $1 === match ) return 0
  if ( $1 === list ) {
    if ( %api_keys > 0 ) {
      ;; Select the last selected API account data in the list, or the first item in the list if we have none set
      did -c oasiz.api 1 $calc(%c - 1)
      writeini -n oasiz.api.ini settings current_api %s

      ;; Check connect button
      var %checkbtn = $oasiz.authtool.checkbutton
    }
    else {
      ;; There's no API data stored, let's be nice and advise them
      $oasiz.authtool.msg(Click "Add" to store your first Oasiz API account details)

      ;; We should also disable the delete/update/connect buttons..
      did -b $dname 365 | did -b $dname 8 | did -b $dname 34
    }
    $oasiz.authtool.lastupdated($readini(oasiz.api.ini, n, settings, current_api))
    if ( $did(oasiz.api,1).seltext === $null ) {
      ;; Only shown after deleting API account. I think.
      ;; No API account data selected - disable delete, update and connect buttons
      did -b oasiz.api 365 | did -b oasiz.api 8 | did -b oasiz.api 34
      $oasiz.authtool.lastupdated(reset)
    }
    else {
      ;; We have an API account selected
      ;; Enable "delete/update" buttons
      did -e oasiz.api 365 | did -e oasiz.api 8
    }
  }
}

;; Send API call to authorisation script
alias oasiz.authtool.api.update {
  $api(ADD, $readini(oasiz.api.ini, n, $readini(oasiz.api.ini, n, settings, current_api), k), $readini(oasiz.api.ini, n, $readini(oasiz.api.ini, n, settings, current_api), p))
}

alias oasiz.authtool.setserver {
  var %c = 0
  if ( $did($dname,110).state === 1 ) %c = 3
  if ( $did($dname,130).state === 1 ) %c = %c + 5
  if ( %c === 3 ) %c = M
  if ( %c === 5 ) %c = G
  if ( %c === 8 ) %c = B
  writeini -n oasiz.api.ini settings s %c
  var %checkbtn = $oasiz.authtool.checkbutton
}

alias oasiz.authtool.getserver {
  if ($1 === G) return 147.124.219.168
  return 147.124.219.169
}

alias oasiz.authtool.connect {
  var %svr = $readini(oasiz.api.ini,n,settings,s)
  if ( %svr !== B ) {
    server $oasiz.authtool.getserver(%svr)
  }
  else {
    server $oasiz.authtool.getserver(M)
    server -m $oasiz.authtool.getserver(G)
  }
}

alias oasiz.api.statusPrint {
  echo -s $chr(3) $+ $1 $+ $2-
}

alias oasiz.api.callback {
  if ( $1 === 1 ) {
    ;; Loading API data
    $oasiz.authtool.msg($2-)
  }
  elseif ( $1 === 2 ) {
    ;; Successfully loaded API data

    writeini -n oasiz.api.ini $readini(oasiz.api.ini, n, settings, current_api) a $2
    writeini -n oasiz.api.ini $readini(oasiz.api.ini, n, settings, current_api) u $asctime(dd/mm/yy h:nnTT)

    if ( $dialog(oasiz.api) ) {
      var %st = Authentication data successfully loaded. 
      ;; Enable add/delete buttons
      did -e oasiz.api 346 | did -e oasiz.api 365
      ;; Enable connect button IF we have a server selected
      var %checkbtn = $oasiz.authtool.checkbutton
      if ( %checkbtn === $null ) {
        %st = %st $+ $chr(32) $+ Select server(s) to join.
      }
      $oasiz.authtool.msg(%st)
      $oasiz.authtool.lastupdated($readini(oasiz.api.ini, n, settings, current_api))
    }
    else {
      ;; This is likely to be a failed-auth reconnection, let's try and reconnect here
      $oasiz.api.statusprint(3,Reconnecting..)
      .oasiz.authtool.connect
    }
  }
  elseif ( $1 === 7 ) {
    ;; API Authentication error
    $oasiz.authtool.msg(API Error: $2)
    ;; Enable add/delete buttons
    if ( $dialog(oasiz.api) ) {
      did -e oasiz.api 346 | did -e oasiz.api 365
    }
    .disconnect
  }
  elseif ( $1 === 8 ) {
    ;; IRCx Authentication failed, $2 = raw 910 or 911
    if ( $2 == 910 ) {
      $oasiz.api.statusprint(4,Authentication failed. Updating passport..)
      $oasiz.authtool.api.update
    }
    elseif ( $2 == 911 ) {
      $oasiz.api.statusprint(4,Authentication suspended for this IP. Wait 5 minutes before attempting re-auth.)
    }
  }
  else {
    ;; echo -s Unknown API error code ( $+ $1 $+ )
  }
}
