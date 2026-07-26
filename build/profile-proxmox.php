#!/usr/local/bin/php
<?php

/*
 * Copyright (C) 2026 Biptec
 * All rights reserved.
 */

if ($argc !== 2) {
    fwrite(STDERR, sprintf("Usage: %s config.xml\n", basename($argv[0])));
    exit(1);
}

$document = new DOMDocument();
$document->preserveWhiteSpace = false;
$document->formatOutput = true;
if (!$document->load($argv[1])) {
    fwrite(STDERR, sprintf("Unable to load %s\n", $argv[1]));
    exit(1);
}

$xpath = new DOMXPath($document);
$root = $xpath->query('/opnsense')->item(0);
if (!$root instanceof DOMElement) {
    fwrite(STDERR, "Missing XML node: /opnsense\n");
    exit(1);
}

$opnsense = $xpath->query('/opnsense/OPNsense')->item(0);
if (!$opnsense instanceof DOMElement) {
    $opnsense = $document->createElement('OPNsense');
    $root->appendChild($opnsense);
}

$qemu = $xpath->query('/opnsense/OPNsense/QemuGuestAgent')->item(0);
if (!$qemu instanceof DOMElement) {
    $qemu = $document->createElement('QemuGuestAgent');
    $opnsense->appendChild($qemu);
}

$general = $xpath->query('/opnsense/OPNsense/QemuGuestAgent/general')->item(0);
if (!$general instanceof DOMElement) {
    $general = $document->createElement('general');
    $qemu->appendChild($general);
}

$enabled = $xpath->query('/opnsense/OPNsense/QemuGuestAgent/general/Enabled')->item(0);
if (!$enabled instanceof DOMElement) {
    $enabled = $document->createElement('Enabled');
    $general->appendChild($enabled);
}
$enabled->nodeValue = '1';

if ($document->save($argv[1]) === false) {
    fwrite(STDERR, sprintf("Unable to save %s\n", $argv[1]));
    exit(1);
}
