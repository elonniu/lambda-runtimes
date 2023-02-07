<?php declare(strict_types=1);

require_once __DIR__ . '/utils.php';

$arch = exec('arch');

success("The arch is: $arch");

success("The argv is: " . $_SERVER['argv'][1]);

$expectedExtensions = [
//	'bcmath',
'ctype',
'curl',
'date',
'dom',
'exif',
'fileinfo',
'filter',
//	'ftp',
'gettext',
'hash',
'iconv',
'json',
'libxml',
'mbstring',
'mysqlnd',
'Zend OPcache',
'openssl',
'pcntl',
'pcre',
'PDO',
//	'pdo_sqlite',
'pdo_mysql',
'Phar',
'posix',
//	'readline',
'Reflection',
'session',
'SimpleXML',
//	'sodium',
'soap',
'sockets',
'SPL',
//	'sqlite3',
'tokenizer',
'xml',
'xmlreader',
'xmlwriter',
//	'xsl',
'zlib',
];
$loadedExtensions   = get_loaded_extensions();
$missingExtensions  = array_diff($expectedExtensions, $loadedExtensions);
if ($missingExtensions) {
	error('The following extensions are missing: ' . implode(', ', $missingExtensions));
}

// The tests below are more robust: sometimes an extension is "loaded" but broken (e.g. a system lib missing)
$coreExtensions = [
	'date' => class_exists(\DateTime::class),
	'filter_var' => filter_var('elonniu@amazon.com', FILTER_VALIDATE_EMAIL),
	'hash' => hash('md5', 'aws') === 'ac68bbf921d953d1cfab916cb6120864',
	'libxml' => class_exists(\LibXMLError::class),
	'openssl' => strlen(openssl_random_pseudo_bytes(1)) === 1,
	'pntcl' => function_exists('pcntl_fork'),
	'pcre' => preg_match('/abc/', 'abcde', $matches) && $matches[0] === 'abc',
	//	'readline' => READLINE_LIB === 'libedit',
	//	'readline' => READLINE_LIB === 'readline',
	'reflection' => class_exists(\ReflectionClass::class),
	'session' => session_status() === PHP_SESSION_NONE,
	'zip' => class_exists(\ZipArchive::class),
	'zlib' => md5(gzcompress('abcde')) === 'db245560922b42f1935e73e20b30980e',
];

foreach ($coreExtensions as $extension => $test) {
	if (!$test) {
		error($extension . ' core extension was not loaded');
	}
	success("[Core extension] $extension");
}

$extensions = [
	'cURL' => function_exists('curl_init'),
	'json' => function_exists('json_encode'),
	//	'bcmath' => function_exists('bcadd'),
	'ctype' => function_exists('ctype_digit'),
	'dom' => class_exists(\DOMDocument::class),
	'exif' => function_exists('exif_imagetype'),
	'fileinfo' => function_exists('finfo_file'),
	//	'ftp' => function_exists('ftp_connect'),
	'gettext' => function_exists('gettext'),
	'iconv' => function_exists('iconv_strlen'),
	'mbstring' => function_exists('mb_strlen'),
	'opcache' => ini_get('opcache.enable') == 1 && ini_get('opcache.enable_cli') == 1,
	'pdo' => class_exists(\PDO::class),
	'pdo_mysql' => extension_loaded('pdo_mysql'),
	//	'pdo_sqlite' => extension_loaded('pdo_sqlite'),
	'phar' => extension_loaded('phar'),
	'posix' => function_exists('posix_getpgid'),
	'simplexml' => class_exists(\SimpleXMLElement::class),
	//	'sodium' => class_exists('sodium_add'),
	'soap' => class_exists(\SoapClient::class),
	'sockets' => function_exists('socket_connect'),
	'spl' => class_exists(\SplQueue::class),
	//	'sqlite3' => class_exists(\SQLite3::class),
	'tokenizer' => function_exists('token_get_all'),
	'xml' => function_exists('xml_parse'),
	'xmlreader' => class_exists(\XMLReader::class),
	'xmlwriter' => class_exists(\XMLWriter::class),
	//	'xsl' => class_exists(\XSLTProcessor::class),
];
foreach ($extensions as $extension => $test) {
	if (!$test) {
		error($extension . ' extension was not loaded');
	}
	success("[Extension] $extension");
}

$extensionsDisabledByDefault = [
	'intl' => class_exists(\Collator::class),
	'apcu' => function_exists('apcu_add'),
	'pdo_pgsql' => extension_loaded('pdo_pgsql'),
];
foreach ($extensionsDisabledByDefault as $extension => $test) {
	if ($test) {
		error($extension . ' extension was not supposed to be loaded');
	}
	success("[Extension] $extension (disabled)");
}
