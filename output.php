<?php
$handle = fopen ("output.txt", "r");
while (!feof($handle)) {
    $buffer = fgets($handle);
    echo $buffer;
}
fclose ($handle);
?>
