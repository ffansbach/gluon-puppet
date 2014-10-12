<?php

$peers_dir = '/etc/fastd/<%= @community %>/peers';

$validation = [ 'missing' => [], 'invalid' => [] ];

if(!isset($_POST['hostname']) || $_POST['hostname'] == '') {
    $validation['missing'][] = 'hostname';
}

if(!preg_match('/^[0-9a-zA-Z_-]{1,32}$/', $_POST['hostname']))  {
    $validation['invalid'][] = 'hostname';
}

if(!isset($_POST['key']) || $_POST['key'] == '') {
    $validation['missing'][] = 'key';
}

if(!preg_match('/^[0-9a-z]{64}$/', $_POST['key']))  {
    $validation['invalid'][] = 'key';
}

if(!empty($validation['missing']) || !empty($validation['invalid'])) {
    header($_SERVER['SERVER_PROTOCOL'].' 400 Bad Request'); 
    echo json_encode([ 'type' => 'ValidationError', 'validationResult' => $validation ]);
    exit;
}

$target_file = $peers_dir.'/'.$_POST['hostname'];

if(file_exists($target_file)) {
    header($_SERVER['SERVER_PROTOCOL'].' 400 Bad Request'); 
    echo json_encode([ 'type' => 'NodeEntryAlreadyExistsError', 'hostname' => $_POST['hostname'] ]);
    exit;
}

if(!file_put_contents($target_file, 'key "'.$_POST['key'].'";'))
{
    header($_SERVER['SERVER_PROTOCOL'].' 500 Internal Server Error'); 
    echo json_encode([ 'type' => 'PeersDirectoryNotWritable' ]);
    exit;
}

system("/usr/bin/sudo /srv/site-<%= @community %>/router-anmelden/kill-helper");
echo 'ok';
