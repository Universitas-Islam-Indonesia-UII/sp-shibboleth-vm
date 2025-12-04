<?php
session_start();
session_destroy();

//--- Logout Shibboleth ---//
//header("Location: Shibboleth.sso/Logout");

//--- Logout Manual ---//
header("Location: index.php");
exit();
?>