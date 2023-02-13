<?php

// autoload_static.php @generated by Composer

namespace Composer\Autoload;

class ComposerStaticInit1dd2aef7b3ddc8505cc8b5f118e9154f
{
    public static $prefixLengthsPsr4 = array (
        'A' => 
        array (
            'App\\' => 4,
        ),
    );

    public static $prefixDirsPsr4 = array (
        'App\\' => 
        array (
            0 => __DIR__ . '/../..' . '/',
        ),
    );

    public static $classMap = array (
        'Composer\\InstalledVersions' => __DIR__ . '/..' . '/composer/InstalledVersions.php',
    );

    public static function getInitializer(ClassLoader $loader)
    {
        return \Closure::bind(function () use ($loader) {
            $loader->prefixLengthsPsr4 = ComposerStaticInit1dd2aef7b3ddc8505cc8b5f118e9154f::$prefixLengthsPsr4;
            $loader->prefixDirsPsr4 = ComposerStaticInit1dd2aef7b3ddc8505cc8b5f118e9154f::$prefixDirsPsr4;
            $loader->classMap = ComposerStaticInit1dd2aef7b3ddc8505cc8b5f118e9154f::$classMap;

        }, null, ClassLoader::class);
    }
}
