/*
 * Copyright (c) 2019-present, salesforce.com, inc.
 * All rights reserved.
 * Redistribution and use of this software in source and binary forms, with or
 * without modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * - Neither the name of salesforce.com, inc. nor the names of its contributors
 * may be used to endorse or promote products derived from this software without
 * specific prior written permission of salesforce.com, inc.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
package com.salesforce.androidsdk.mobilesync.manager;


import com.salesforce.androidsdk.mobilesync.target.AdvancedSyncUpTarget;
import com.salesforce.androidsdk.mobilesync.target.SyncUpTarget;
import com.salesforce.androidsdk.mobilesync.util.SyncOptions;
import com.salesforce.androidsdk.mobilesync.util.SyncState;
import com.salesforce.androidsdk.mobilesync.util.SyncState.MergeMode;
import com.salesforce.androidsdk.smartstore.store.SmartStore;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Runnable class responsible for running a sync up that uses and AdvancedSyncUpTarget
 */
public class AdvancedSyncUpTask extends SyncUpTask {

    public AdvancedSyncUpTask(SyncManager syncManager, SyncState sync, SyncManager.SyncUpdateCallback callback) {
        super(syncManager, sync, callback);
    }

    @Override
    protected void syncUp(SyncState sync, SyncManager.SyncUpdateCallback callback, List<String> dirtyRecordIds) throws JSONException, IOException {
        final String soupName = sync.getSoupName();
        final SyncUpTarget target = (SyncUpTarget) sync.getTarget();
        final SyncOptions options = sync.getOptions();
        int totalSize = dirtyRecordIds.size();
        int maxBatchSize = ((AdvancedSyncUpTarget) target).getMaxBatchSize();
        List<JSONObject> batch = new ArrayList<>();

        updateSync(sync, SyncState.Status.RUNNING, 0, callback);
        List<JSONObject> dirtyRecords = target.getFromLocalStore(syncManager, soupName, dirtyRecordIds);

        // Figuring out what records need to be synced up based on merge mode and last mod date on server
        Map<String, Boolean> recordIdToShouldSyncUp = shouldSyncUpRecords(syncManager, target, dirtyRecords, options);

        // Syncing up records
        for (int i=0; i<totalSize; i++) {
            checkIfStopRequested();

            JSONObject record = dirtyRecords.get(i);
            String recordId = record.getString(SmartStore.SOUP_ENTRY_ID);

            if (Boolean.TRUE.equals(recordIdToShouldSyncUp.get(recordId))) {
                batch.add(record);
            }

            // Process batch if max batch size reached or at the end of dirtyRecordIds
            if (batch.size() == maxBatchSize || i == totalSize - 1) {
                ((AdvancedSyncUpTarget) target).syncUpRecords(syncManager, batch, options.getFieldlist(), options.getMergeMode(), sync.getSoupName());
                batch.clear();
            }

            // Updating status
            int progress = (i + 1) * 100 / totalSize;
            if (progress < 100) {
                updateSync(sync, SyncState.Status.RUNNING, progress, callback);
            }
        }
    }

    protected Map<String, Boolean> shouldSyncUpRecords(SyncManager syncManager, SyncUpTarget target, List<JSONObject> records, SyncOptions options) throws IOException, JSONException {
        Map<String, Boolean> recordIdToShouldSyncUp = new HashMap<>();

        if (options.getMergeMode() == MergeMode.OVERWRITE) {
            for (JSONObject record : records) {
                String recordId = record.getString(SmartStore.SOUP_ENTRY_ID);
                recordIdToShouldSyncUp.put(recordId, true);
            }
        } else {
            recordIdToShouldSyncUp = target.areNewerThanServer(syncManager, records);
        }

        return recordIdToShouldSyncUp;
    }
}