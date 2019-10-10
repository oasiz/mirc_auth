;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; Oasiz IRCX Channel/Server Access  ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; VERSION  1.0.0
;; AUTHOR   Rob Hildyard
;; DATE     10.10.19
;; SITE     www.oasiz.com

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

raw 803:*: {
  var %x chan.access
  if ($dialog(%x)) {
    did -ra %x 1 Retrieving access list...
    if ($hget(%x)) hfree %x
    hmake %x 2
    hadd %x num 1
  }
  else {
    linesep -s
    echo -ta Start of access list for $2
  }
  haltdef
}

raw 804:*: {
  var %x chan.access
  if ($dialog(%x)) {
    inc %oaacclc
    hadd %x $hget(%x,num) $3-
    hinc %x num
    did -e %x 1,12,13,14
    dialog -t %x Access List for %oa.lst ( $+ %oaacclc entries)
  }
  else echo $color(mode) -ta * $3-5 $7-
  haltdef
}

raw 805:*: {
  var %a, %l 1, %x chan.access
  if ($dialog(%x)) {
    did -r %x 1
    while (%l <= $hget(%x,num)) {
      %a = $hget(%x,%l)
      did -a %x 1 $gettok(%a,1-2,32)
      inc %l
    }
    did -d %x 1 $did(%x,1).lines
    did -z %x 1
    did -e %x 1
  }
  else {
    echo -ta End of access list for $2
    linesep -s
  }
  haltdef
}

menu channel {
  $iif(($me isop #),$style(0),$style(2)) Channel Access:accesslist $active
}

menu status {
  ;;;;$iif(('* iswm $me),$style(0),$style(2)) Access
  Access
  .Server:accesslist $chr(36)
  .Network:accesslist $chr(42)
}

alias accesslist {
  set %oa.lst $1
  dialog -m chan.access chan.access
}

dialog chan.access {
  title "Access List for..."
  size -1 -1 245 192
  option dbu
  icon $mircexe, 5
  list 1, 1 2 200 107, disable hsbar vsbar
  box "Info", 2, 1 110 200 77
  edit "", 4, 4 117 194 67, read multi vsbar
  button "Add Entry", 12, 203 2 40 12, disable
  button "Delete Entry", 13, 203 16 40 12, disable
  button "Clear DENY", 21, 203 34 40 12, disable
  button "Clear GRANT", 14, 203 48 40 12, disable
  button "Clear VOICE", 18, 203 62 40 12, disable
  button "Clear HOST", 19, 203 76 40 12, disable
  button "Clear OWNER", 20, 203 90 40 12, disable
  button "Refresh List", 15, 203 136 40 12
  button "Export", 16, 203 154 20 12
  button "Import", 17, 223 154 20 12, disable
  button "Done", 99, 203 174 40 12, default cancel
}

alias oa.serv {
  if ( ($1 == $chr(36)) || ($1 == $chr(42)) ) return true
  return false
}

on *:DIALOG:chan.access*:init:*: {
  set %oaacclc 0
  dialog -t $dname Access List for %oa.lst
  did -a $dname 1 Retrieving Access list...
  if ($oa.serv(%oa.lst) == false) {
    if ($me isop %oa.lst) did -e $dname 12,13,14,17,18,19,20
    if ($me isowner %oa.lst) did -e $dname 21
  }
  else {
    did -e $dname 21
  }
  if ($hget($dname)) hfree $dname
  hmake $dname 2
  hadd $dname num 1
  access %oa.lst
}

on *:DIALOG:chan.access*:sclick:1: {
  tokenize 32 $hget($dname,$did(1).sel)
  var %x = Type: $1 $+ $crlf $+ Access Mask: $2 $+ $crlf $+ $iif($3 == 0,No time limit,Remaining time: $3 minutes) $+ $crlf
  if ($ial($2,1).nick) %x = %x $+ Possible match: $ial($2,1).nick $+ $crlf
  %x = %x $+ Placed by: $4 $+ $crlf
  if ($5-) %x = %x $+ Reason: $5- $+ $crlf
  did -ra $dname 4 %x
}

on *:DIALOG:chan.access*:sclick:12: chan.addacc
on *:DIALOG:chan.access*:sclick:13: {
  if ($did(1,$did(1).sel) != $null) {
    access %oa.lst delete $did(1).seltext
    access %oa.lst list
    did -ra $dname 1 Retrieving Access list...
  }
}

on *:DIALOG:chan.access*:sclick:14: chan.access.clear %oa.lst grant
on *:DIALOG:chan.access*:sclick:18: chan.access.clear %oa.lst voice
on *:DIALOG:chan.access*:sclick:19: chan.access.clear %oa.lst host
on *:DIALOG:chan.access*:sclick:20: chan.access.clear %oa.lst owner
on *:DIALOG:chan.access*:sclick:21: chan.access.clear %oa.lst deny

alias -l chan.access.clear {
  if ($input(Are you sure you want to clear the $2 list in $1 $+ ?,264,Clear Access List)) {
    access $1 clear $2
    access %oa.lst
    did -r chan.access 1
  }
}

on *:DIALOG:chan.access*:sclick:15: {
  access %oa.lst list
  did -ra $dname 1 Retrieving Access list...
}

on *:DIALOG:chan.access*:sclick:16: {
  var %a, %x $dname, %l $calc($hget(%x,num) - 1), %f access- $+ $mkfn(%oa.lst) $+ .txt
  if ($isfile($scriptdir $+ %f)) .remove " $+ $scriptdir $+ %f $+ "
  while (%l >= 1) {
    %a = $hget(%x,%l)
    write " $+ $scriptdir $+ %f $+ " $gettok(%a,1-3,32) : $+ $gettok(%a,5-,32)
    dec %l
  }
  %f = $input(Access list was saved successfully to: $+ $crlf $+ %f ,68,Access saved)
}

on *:DIALOG:chan.access*:sclick:17: {
  var %f " $+ $$sfile($scriptdir $+ *.txt,Choose a saved access list to import,Import) $+ "
  if ($hget(oasiz.accimp)) {
    echo $color(mode) -ta * Please wait, already importing a access list
    return
  }
  hmake oasiz.accimp 3
  hload -n oasiz.accimp %f
  %msnt.accimp = 1
  did -rab $dname 1 Importing Access list, please wait...
  did -r $dname 4
  .timer. $+ oasiz.accimp -m 0 500 oasiz.accimport oasiz.accimp
}

alias oasiz.accimport {
  if ($hget($1,%msnt.accimp) == $null) {
    if ($dialog(chan.access)) {
      did -ra chan.access 1 Retrieving Access list...
      access %oa.lst
    }
    .timer. $+ $1 off
    unset %msnt.accimp
    hfree $1
  }
  else {
    access %oa.lst ADD $remove($hget($1,%msnt.accimp),?)
    inc %msnt.accimp
  }
}

on *:DIALOG:chan.access*:sclick:99: hfree $dname

alias chan.addacc dialog -m chan.addacc chan.addacc

dialog chan.addacc {
  title "Add Access Entry"
  icon $mircexe , 5
  size -1 -1 150 67
  option dbu
  text "Type:", 1, 1 4 40 7, right
  combo 2, 45 2 103 50, drop
  text "Access Mask:", 3, 1 16 40 7, right
  edit "", 4, 45 14 103 11, autohs
  text "Amount of time:", 5, 1 28 40 7, right
  edit "0", 6, 45 26 25 11
  text "minutes", 7, 72 28 20 7
  text "Reason:", 8, 1 40 40 7, right
  edit "", 9, 45 38 103 11, autohs
  button "Add", 99, 64 52 40 12, ok
  button "Cancel", 98, 107 52 40 12, cancel
}

on *:DIALOG:chan.addacc*:init:*: {
  if ($oa.serv(%oa.lst) == false) {
    if ($me isowner %oa.lst) did -a $dname 2 Owner
    did -a $dname 2 Host
    did -a $dname 2 Voice
  }
  did -a $dname 2 Grant
  did -a $dname 2 Deny
  did -c $dname 2 1
}

on *:DIALOG:chan.addacc*:sclick:99: {
  if (!$did(4)) halt
  access %oa.lst add $did(2).seltext $did(4) $did(6) : $+ $did(9)
  if ($dialog(chan.access)) access %oa.lst
}
