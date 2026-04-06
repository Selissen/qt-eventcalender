library design_system;

// Remaining legacy components (AppLoadingSpinner, AppErrorView, AppSidebar,
// AppDialog, LoadingView, ErrorView, EmptyView) still in use — pending migration
export 'src/widgets/app_scaffold.dart';   // AppLoadingSpinner, AppErrorView
export 'src/widgets/app_dialog.dart';
export 'src/widgets/app_sidebar.dart';
export 'src/widgets/loading_error_empty.dart';

// G Design System
export 'design_system/design_system.dart';
// Dev-only kitchen sink (not included in design_system.dart barrel)
export 'design_system/examples/g_kitchen_sink.dart';
