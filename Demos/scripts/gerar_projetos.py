#!/usr/bin/env python3
"""Regenera projetos autocontidos sem instalar XcodeGen ou outras dependências."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
APPS = {'ListaCompras': 'Compras', 'LeituraFacil': 'Leitura', 'MinhaRotina': 'Rotina'}


def quoted(value):
    return json.dumps(str(value), ensure_ascii=False)


def encode(value, level=0):
    if isinstance(value, dict):
        lines = ['{']
        for key, child in value.items():
            lines.append('\t' * (level + 1) + quoted(key) + ' = ' + encode(child, level + 1) + ';')
        lines.append('\t' * level + '}')
        return '\n'.join(lines)
    if isinstance(value, list):
        return '(' + ', '.join(encode(item, level) for item in value) + (',' if value else '') + ')'
    return quoted(value)


for app, title in APPS.items():
    objects = {}

    def uid(name):
        return hashlib.sha256((app + '/' + name).encode()).hexdigest()[:24].upper()

    def add(object_name, isa, **fields):
        key = uid(object_name)
        objects[key] = dict(isa=isa, **fields)
        return key

    def configuration_list(name, settings):
        ids = []
        for config in ['Debug', 'Release']:
            selected = dict(settings)
            if name == 'project':
                selected.update(SWIFT_OPTIMIZATION_LEVEL='-Onone' if config == 'Debug' else '-O',
                                DEBUG_INFORMATION_FORMAT='dwarf' if config == 'Debug' else 'dwarf-with-dsym',
                                ONLY_ACTIVE_ARCH='YES' if config == 'Debug' else 'NO')
                if config == 'Debug':
                    selected.update(ENABLE_TESTABILITY='YES', SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG $(inherited)')
            ids.append(add(name + config, 'XCBuildConfiguration', name=config, buildSettings=selected))
        return add(name + 'configs', 'XCConfigurationList', buildConfigurations=ids,
                   defaultConfigurationIsVisible=0, defaultConfigurationName='Release')

    project_config = configuration_list('project', dict(
        SDKROOT='iphoneos', IPHONEOS_DEPLOYMENT_TARGET='17.0', SWIFT_VERSION='5.0',
        CLANG_ENABLE_MODULES='YES', CLANG_ENABLE_OBJC_ARC='YES',
        ENABLE_USER_SCRIPT_SANDBOXING='YES', GCC_C_LANGUAGE_STANDARD='gnu17',
        ALWAYS_SEARCH_USER_PATHS='NO', COPY_PHASE_STRIP='NO'))
    package = add('checker', 'XCLocalSwiftPackageReference', relativePath='../..')
    shared = add('shared-app', 'PBXFileReference', lastKnownFileType='sourcecode.swift', path='App.swift', sourceTree='<group>')
    groups = [add('shared-group', 'PBXGroup', children=[shared], path='Shared', sourceTree='<group>')]
    targets, products = [], []
    for variant, suffix in [('ComProblemas', 'Antes'), ('Corrigido', 'Depois')]:
        target = app + '-' + variant
        source = add(variant+'source', 'PBXFileReference', lastKnownFileType='sourcecode.swift', path='ContentView.swift', sourceTree='<group>')
        groups.append(add(variant+'group', 'PBXGroup', children=[source], path=variant, sourceTree='<group>'))
        files = [add(variant+key+'build', 'PBXBuildFile', fileRef=ref) for key, ref in [('app', shared), ('view', source)]]
        sources = add(variant+'sources', 'PBXSourcesBuildPhase', buildActionMask=2147483647, files=files, runOnlyForDeploymentPostprocessing=0)
        frameworks = add(variant+'frameworks', 'PBXFrameworksBuildPhase', buildActionMask=2147483647, files=[], runOnlyForDeploymentPostprocessing=0)
        resources = add(variant+'resources', 'PBXResourcesBuildPhase', buildActionMask=2147483647, files=[], runOnlyForDeploymentPostprocessing=0)
        product = add(variant+'product', 'PBXFileReference', explicitFileType='wrapper.application', includeInIndex=0, path=target+'.app', sourceTree='BUILT_PRODUCTS_DIR')
        products.append(product)
        plugin = add(variant+'plugin', 'XCSwiftPackageProductDependency', package=package, productName='plugin:SwiftAccessibilityCheckerPlugin')
        dep = add(variant+'dependency', 'PBXTargetDependency', productRef=plugin)
        configs = configuration_list(variant, dict(
            PRODUCT_NAME='$(TARGET_NAME)', PRODUCT_BUNDLE_IDENTIFIER='br.edu.tcc.sac.'+app.lower()+'.'+variant.lower(),
            CODE_SIGN_STYLE='Automatic', CURRENT_PROJECT_VERSION=1, MARKETING_VERSION='1.0',
            GENERATE_INFOPLIST_FILE='YES', INFOPLIST_KEY_CFBundleDisplayName=title+' '+suffix,
            INFOPLIST_KEY_LSApplicationCategoryType='public.app-category.education',
            INFOPLIST_KEY_UIApplicationSceneManifest_Generation='YES',
            INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents='YES',
            INFOPLIST_KEY_UILaunchScreen_Generation='YES',
            INFOPLIST_KEY_UISupportedInterfaceOrientations='UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight',
            TARGETED_DEVICE_FAMILY='1', SUPPORTED_PLATFORMS='iphoneos iphonesimulator',
            SUPPORTS_MACCATALYST='NO', SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD='NO',
            LD_RUNPATH_SEARCH_PATHS=['$(inherited)', '@executable_path/Frameworks'],
            SWIFT_EMIT_LOC_STRINGS='YES'))
        target_id = add(variant+'target', 'PBXNativeTarget', name=target, productName=target, productReference=product,
                       productType='com.apple.product-type.application', buildConfigurationList=configs,
                       buildPhases=[sources, frameworks, resources], buildRules=[], dependencies=[dep], packageProductDependencies=[])
        targets.append(target_id)
        scheme_dir = ROOT / app / (app+'.xcodeproj') / 'xcshareddata/xcschemes'
        scheme_dir.mkdir(parents=True, exist_ok=True)
        ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target_id}" BuildableName="{target}.app" BlueprintName="{target}" ReferencedContainer="container:{app}.xcodeproj"/>'
        (scheme_dir/(target+'.xcscheme')).write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables/></TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
    <BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
    products_group = add('products', 'PBXGroup', name='Products', children=products, sourceTree='<group>')
    main = add('main', 'PBXGroup', children=groups+[products_group], sourceTree='<group>')
    project = add('project', 'PBXProject', attributes=dict(LastUpgradeCheck='2700', BuildIndependentTargetsInParallel='YES'),
                  buildConfigurationList=project_config, compatibilityVersion='Xcode 15.0', developmentRegion='pt-BR',
                  hasScannedForEncodings=0, knownRegions=['pt-BR', 'en', 'Base'], mainGroup=main, productRefGroup=products_group,
                  projectDirPath='', projectRoot='', targets=targets, packageReferences=[package])
    pbx = dict(archiveVersion=1, classes={}, objectVersion=60, objects=objects, rootObject=project)
    (ROOT/app/(app+'.xcodeproj')/'project.pbxproj').write_text('// !$*UTF8*$!\n'+encode(pbx)+'\n')

workspace = ROOT/'Demo.xcworkspace'
workspace.mkdir(exist_ok=True)
(workspace/'contents.xcworkspacedata').write_text('<?xml version="1.0" encoding="UTF-8"?>\n<Workspace version="1.0">\n'+''.join(f'  <FileRef location="group:{app}/{app}.xcodeproj"/>\n' for app in APPS)+'</Workspace>\n')
print('3 projetos, 6 schemes e Demo.xcworkspace gerados.')
