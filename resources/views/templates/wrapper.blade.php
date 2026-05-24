<!DOCTYPE html>
<html>
    <head>
        <title>{{ config('app.name', 'Pterodactyl') }}</title>

        @section('meta')
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
            <meta name="csrf-token" content="{{ csrf_token() }}">
            <meta name="robots" content="noindex">
            <link rel="apple-touch-icon" sizes="180x180" href="/favicons/apple-touch-icon.png">
            <link rel="icon" type="image/png" href="/favicons/favicon-32x32.png" sizes="32x32">
            <link rel="icon" type="image/png" href="/favicons/favicon-16x16.png" sizes="16x16">
            <link rel="manifest" href="/favicons/manifest.json">
            <link rel="mask-icon" href="/favicons/safari-pinned-tab.svg" color="#bc6e3c">
            <link rel="shortcut icon" href="/favicons/favicon.ico">
            <meta name="msapplication-TileColor" content="#00a300">
            <meta name="msapplication-config" content="/favicons/browserconfig.xml">
            <meta name="theme-color" content="#150f23">
            <link rel="preconnect" href="https://fonts.googleapis.com">
            <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        @show

        @section('user-data')
            @if(!empty($siteConfiguration))
                <script>
                    window.SiteConfiguration = {!! json_encode($siteConfiguration) !!};
                </script>
            @endif
            @if(!empty($user))
                <script>
                    window.User = {!! json_encode($user) !!};
                </script>
            @endif
        @show

        @section('assets')
            @css('assets/app.css')
            <link rel="stylesheet" href="/themes/sentri-pterodactyl-dark/theme.css?v={{ file_exists(public_path('themes/sentri-pterodactyl-dark/theme.css')) ? filemtime(public_path('themes/sentri-pterodactyl-dark/theme.css')) : time() }}" data-theme="sentri-pterodactyl-dark">
        @show
    </head>
    <body class="sentri-theme">
        @section('content')
            <div id="app"></div>
        @show
        @section('scripts')
            {!! $asset->js('app.js') !!}
        @show
    </body>
</html>
