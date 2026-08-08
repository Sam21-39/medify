import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

import '../remote_config/feature_flags.dart';
import '../remote_config/remote_config_service.dart';

/// Zero-layout-impact placeholder when `ads_enabled == false` (the default
/// through at least v2.2.0). Provider SDK integration is wired but inert —
/// no ad requests, no consent-flow prompts, no SDK network calls while the
/// flag is off. This is scaffolding, not a soft-launch (Section 13).
class AdSlotWidget extends StatelessWidget {
  const AdSlotWidget({super.key, this.remoteConfigService});

  final RemoteConfigService? remoteConfigService;

  @override
  Widget build(BuildContext context) {
    final config = remoteConfigService ?? GetIt.instance<RemoteConfigService>();
    if (!config.isEnabled(FeatureFlag.adsEnabled)) {
      return const SizedBox.shrink();
    }
    // TODO(ads): render the provider SDK's ad widget (e.g. AdMob banner)
    // once ads_enabled is deliberately flipped.
    return const SizedBox.shrink();
  }
}
