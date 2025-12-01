<?php
echo 'Nama: '. $_SERVER['Shib-displayname']. '<br>';
echo 'Username: '. $_SERVER['Shib-uid']. '<br>';
echo 'Email: '. $_SERVER['Shib-mail']. '<br>';
echo 'Group: <br>';
$members = explode(';', $_SERVER['Shib-memberof']);
foreach($members as $i=>$v) {
   echo '- '.$v. '<br>';
}
?>