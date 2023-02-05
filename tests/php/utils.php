<?php declare(strict_types=1);

/**
 * @param string $message
 * @return void
 */
function success(string $message)
{
	echo "✓ $message" . PHP_EOL;
}

/**
 * @param string $message
 * @return void
 */
function error(string $message)
{
	echo "⨯ $message" . PHP_EOL;
	exit(1);
}
