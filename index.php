<?php
session_start();

//--- Login Shibboleth ---//
//echo'<pre>';print_r($_SERVER);exit;
//if (isset($_SERVER['Shib-uid'])) {
//    $_SESSION['userid'] = $_SERVER['Shib-uid'];
//    $_SESSION['email'] = $_SERVER['Shib-mail'];
//    $_SESSION['username'] = $_SERVER['Shib-displayname'];

// Jika sudah login, langsung ke halaman dashboard
if (isset($_SESSION['username'])) {
   echo "
   <!DOCTYPE html>
   <html>
   <head>
      <title>Dashboard</title>
   </head>
   <body>

   <h2>Selamat datang, $_SESSION[nama]</h2>
   <p>Email: $_SESSION[email]</p>
   <p>User ID: $_SESSION[username]</p>

   <a href='logout.php'>Logout</a>

   </body>
   </html>
   ";
    exit;
}

// Data user statis (tanpa database)
$users = [
    [
        "username" => "satu",
        "email"   => "user1@mail.com",
        "nama"   => "User Satu",
        "password" => "password1"
    ],
    [
        "username" => "dua",
        "email"   => "user2@mail.com",
        "nama"   => "User Dua",
        "password" => "password2"
    ]
];

$error = "";

// Jika tombol login ditekan
if ($_SERVER['REQUEST_METHOD'] === "POST") {
    $username    = $_POST['username'] ?? "";
    $password = $_POST['password'] ?? "";

    $found = false;

    foreach ($users as $u) {
        if ($u['username'] === $username && $u['password'] === $password) {
            // Set session
            $_SESSION['username'] = $u['username'];
            $_SESSION['email']   = $u['email'];
            $_SESSION['nama']   = $u['nama'];

            header("Location: index.php");
            exit();
        }
    }

    // Jika tidak ditemukan
    $error = "Username atau password salah!";
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Login</title>
</head>
<body>
    <h2>Halaman Login</h2>
    <div>List User
    <ul style="margin-top:0;margin-left:-20px">
        <li>satu : password1</li>
        <li>dua : password2</li>
    </ul>
    </div>
    <?php if ($error): ?>
        <p style="color:red;"><?= $error ?></p>
    <?php endif; ?>

    <form method="POST">
        <label>Username</label><br>
        <input type="text" name="username" required><br><br>

        <label>Password</label><br>
        <input type="password" name="password" required><br><br>

        <button type="submit">Login</button>
    </form>
</body>
</html>