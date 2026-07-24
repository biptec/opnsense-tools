#!/usr/local/bin/php
<?php

/*
 * Copyright (C) 2026 Biptec
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
$system = $xpath->query('/opnsense/system')->item(0);
if (!$system instanceof DOMElement) {
    fwrite(STDERR, "Missing XML node: /opnsense/system\n");
    exit(1);
}

$disableFilter = $xpath->query('/opnsense/system/disablefilter')->item(0);
if (!$disableFilter instanceof DOMElement) {
    $disableFilter = $document->createElement('disablefilter');
    $system->appendChild($disableFilter);
}
$disableFilter->nodeValue = 'enabled';
if ($document->save($argv[1]) === false) {
    fwrite(STDERR, sprintf("Unable to save %s\n", $argv[1]));
    exit(1);
}
