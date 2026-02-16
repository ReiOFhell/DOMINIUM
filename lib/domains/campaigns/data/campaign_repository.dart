import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/campaigns/data/campaign.dart';
import 'package:hive/hive.dart';

class CampaignRepository {
  CampaignRepository(this._box);

  final Box<Map> _box;

  factory CampaignRepository.fromHive() =>
      CampaignRepository(Hive.box<Map>(HiveBootstrap.campaignsBox));

  List<Campaign> all() => _box.values.map(Campaign.fromMap).toList();

  Future<void> upsert(Campaign campaign) => _box.put(campaign.id, campaign.toMap());

  Future<void> delete(String id) => _box.delete(id);
}
