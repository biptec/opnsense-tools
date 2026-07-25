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

$configPath = $argv[1];
$document = new DOMDocument();
$document->preserveWhiteSpace = false;
$document->formatOutput = true;
if (!$document->load($configPath)) {
    fwrite(STDERR, sprintf("Unable to load %s\n", $configPath));
    exit(1);
}

$xpath = new DOMXPath($document);

function requireElement(DOMXPath $xpath, string $path): DOMElement
{
    $node = $xpath->query($path)->item(0);
    if (!$node instanceof DOMElement) {
        throw new RuntimeException(sprintf('Missing XML node: %s', $path));
    }
    return $node;
}

function setChild(DOMDocument $document, DOMElement $parent, string $name, string $value = ''): void
{
    foreach ($parent->childNodes as $child) {
        if ($child instanceof DOMElement && $child->tagName === $name) {
            $child->nodeValue = $value;
            return;
        }
    }
    $element = $document->createElement($name);
    $element->nodeValue = $value;
    $parent->appendChild($element);
}

function removeChildren(DOMElement $parent, array $names): void
{
    foreach (iterator_to_array($parent->childNodes) as $child) {
        if ($child instanceof DOMElement && in_array($child->tagName, $names, true)) {
            $parent->removeChild($child);
        }
    }
}

try {
    $ssh = requireElement($xpath, '/opnsense/system/ssh');
    setChild($document, $ssh, 'noauto', '1');
    setChild($document, $ssh, 'enabled', 'enabled');
    removeChildren($ssh, ['passwordauth', 'permitrootlogin']);

    $lan = requireElement($xpath, '/opnsense/interfaces/lan');
    setChild($document, $lan, 'ipaddr', 'dhcp');
    setChild($document, $lan, 'subnet');
    setChild($document, $lan, 'dhcphostname');

    foreach ($xpath->query("/opnsense/dnsmasq/dhcp_ranges[interface='lan' and not(contains(start_addr, ':'))]") as $range) {
        $range->parentNode->removeChild($range);
    }
} catch (RuntimeException $exception) {
    fwrite(STDERR, $exception->getMessage() . "\n");
    exit(1);
}

if ($document->save($configPath) === false) {
    fwrite(STDERR, sprintf("Unable to save %s\n", $configPath));
    exit(1);
}
