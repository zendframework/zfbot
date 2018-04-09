#!/usr/bin/env php
<?php
/**
 * Generate the docker-stack.yml file from latest images.
 *
 * Usage:
 *
 *   create-docker-stack.php -n $NGINX_VERSION -b $ZFBOT_VERSION -c $CADDY_VERSION
 *
 * If any is listed as "latest", this script will delegate to
 * get-latest-tag.php to identify the latest tag released for that
 * container.
 */

const REPOS = ['zfbot-nginx', 'zfbot', 'zfbot-caddy'];
const STACKFILE = 'docker-stack.yml';
const TAGSCRIPT = './bin/get-latest-tag.php';
const TEMPLATE = 'docker-stack.yml.dist';
const USER = 'mwop';

chdir(dirname(__DIR__));

if ($argc < 7) {
    fwrite(STDERR, sprintf('Missing one or more arguments.%s', str_repeat(PHP_EOL, 2)));
    usage(STDERR, $argv[0]);
    exit(1);
}

if ($argv[1] !== '-n' || $argv[3] !== '-b' || $argv[5] !== '-c') {
    fwrite(STDERR, sprintf('Invalid arguments provided.%s', str_repeat(PHP_EOL, 2)));
    usage(STDERR, $argv[0]);
    exit(1);
}

$versions = [
    'zfbot-nginx' => $argv[2],
    'zfbot'       => $argv[4],
    'zfbot-caddy' => $argv[6],
];

$substitutions = [];
foreach (REPOS as $repo) {
    // Was a version provided for this repo?
    if ($versions[$repo] !== 'latest') {
        $substitutions[sprintf('{%s}', $repo)] = $versions[$repo];
        continue;
    }

    // Look up the latest tagged version for this repo
    $command = sprintf('%s %s %s', TAGSCRIPT, USER, $repo);
    exec($command, $output, $return);
    if ($return !== 0) {
        fwrite(STDERR, implode($output, PHP_EOL));
        exit($return);
    }

    $substitutions[sprintf('{%s}', $repo)] = array_shift($output);
}

$stackFile = file_get_contents(TEMPLATE);
$stackFile = str_replace(array_keys($substitutions), array_values($substitutions), $stackFile);

file_put_contents(STACKFILE, $stackFile);

function usage($stream, string $scriptName)
{
    $message = <<<'EOM'
Usage:

  %s -n <nginx version> -b <zfbot version> -c <caddy version>

where:

  <nginx version>     Version tag of nginx container to use
  <zfbot version>     Version tag of zfbot container to use
  <caddy version>     Version tag of caddy container to use

Generates the docker-stack.yml file to use during deployment, using the
specified tags for the nginx and php-fpm containers.

In either case, if the string "latest" is used, this script will look up
the latest tagged version of that container and use that to generate the
docker-stack.yml file.

EOM;

    $message = sprintf($message, $scriptName);
    $message = sprintf("\n", PHP_EOL, $message);
    fwrite($stream, $message);
}
