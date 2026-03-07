import 'package:dominium/domains/campaigns/data/campaign.dart';
import 'package:dominium/domains/campaigns/data/campaign_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final campaignRepositoryProvider =
    Provider<CampaignRepository>((_) => CampaignRepository.fromHive());

final campaignsProvider = StateNotifierProvider<CampaignsController, List<Campaign>>(
  (ref) => CampaignsController(ref.read(campaignRepositoryProvider)),
);

class CampaignsController extends StateNotifier<List<Campaign>> {
  CampaignsController(this._repository) : super(_repository.all());

  final CampaignRepository _repository;

  Future<void> save(Campaign campaign) async {
    await _repository.upsert(campaign);
    state = _repository.all();
  }

  Future<void> remove(String id) async {
    await _repository.delete(id);
    state = _repository.all();
  }
}
