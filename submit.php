<?php
session_start();
require 'vendor/autoload.php';
echo "Submit.php page";
if(!empty($_POST)){
echo $_POST['email'];
echo $_POST['phone'];
}
else {
echo "Post data is empty";
}
print_r ($_POST);
echo $_FILES['userfile'];
print_r ($_FILES);

if (isset ($_FILES['userfile'])){
$uploaddir = '/tmp/';
$uploadfile = $uploaddir. basename($_FILES['userfile']['name']);
if (move_uploaded_file($_FILES['userfile']['tmp_name'], $uploadfile)) {
    print "File is valid, and was successfully uploaded.\n";
} else {
    print "Possible file upload attack!\n";
}
}
else
{

print "file not valid ";
}
print 'Here is some more debugging info:';
print_r($_FILES);

$s3=new Aws\S3\S3Client([
    'version' => 'latest',
    'region'  => 'us-east-1'
]);

$bucket = uniqid("S3-Sukanya-", false);
print "Creating bucket named {$bucket}\n";
$result = $s3->createBucket([
    'ACL' => 'public-read',
    'Bucket' => $bucket
]);


$result = $s3->waitUntil('BucketExists',array('Bucket' => $bucket));

echo "bucket creation done";

$result = $s3->putObject([
    'ACL' => 'public-read',
    'Bucket' => $bucket,
   'Key' => "uploads".$uploadfile,
'ContentType' => $_FILES['userfile']['type'],
    'Body'   => fopen($uploadfile, 'r+')
]);  
$url = $result['ObjectURL'];
echo $url;
echo "s3 file uploaded";

$rds = new Aws\Rds\RdsClient([
    'version' => 'latest',
    'region'  => 'us-west-2'
]);

$result = $rds->describeDBInstances(['DBInstanceIdentifier' => 'itmo-544-sukanya']);

echo "No error as of now";

print_r($result);

$endpoint = $result['DBInstances'][0]['Endpoint']['Address'];
    print "============\n". $endpoint . "================";
echo "endpoint is available";

$link = mysqli_connect($endpoint,"SukanyaN","SukanyaNDB","itmo544SNDB") or die("Error " . mysqli_error($link));

print_r($link);

echo "connection success";
/*
if (!($stmt = $link->prepare("INSERT INTO items (id,Uname,Email,Phone,RawS3Url,FinalS3Url,JpgFileName,status,Issubscribed) VALUES (NULL,?,?,?,?,?,?,?,?)"))) {
    print "Prepare failed: (" . $link->errno . ") " . $link->error;
}
else
{
print "statement was success"
}

$uname = $_POST['username'];
$email = $_POST['email'];
$phone = $_POST['phone'];
$s3rawurl = $url; //  $result['ObjectURL']; from above
$s3finishedurl = "none";
$filename = basename($_FILES['userfile']['name']);
$status =0;
$issubscribed=0;
if (!$stmt->bind_param("sssssii",$uname,$email,$phone,$s3rawurl,$s3finishedurl,$filename,$status,$issubscribed)){
echo "binding failed";
}
else
{
echo "binding success";
}
if (!$stmt->execute()) {
    print "Execute failed: (" . $stmt->errno . ") " . $stmt->error;
}
else
{
echo "execution success";
}
printf("%d Row inserted.\n", $stmt->affected_rows);

$stmt->close();
$sql1 = "SELECT * FROM items";
$result = mysqli_query($link, $sql1);
print "Result set order...\n";
*/
$link->close();
?>

 


