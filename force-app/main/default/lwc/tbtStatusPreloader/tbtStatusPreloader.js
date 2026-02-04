import { LightningElement, wire, api } from 'lwc';
import { getListUi } from 'lightning/uiListApi';
import DOCUMENT_OBJECT from '@salesforce/schema/Document__c';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USERNAME_FIELD from '@salesforce/schema/User.Username';

export default class TbtStatusPreloader extends LightningElement {
    @api recordId;
    userName;
    refreshInterval;
    lastRefreshTime;
    isOffline = false;

    // 🟢 ENHANCED - Cache with offline support
    cacheTbtData(tbtDoc, userName, source = 'preloader') {
        const cacheKey = `tbtDoc_${userName}`;
        const cacheData = {
            ...tbtDoc,
            cachedAt: new Date().toISOString(),
            source: source,
            isOffline: this.isOffline
        };
        
        // Use both storage mechanisms
        sessionStorage.setItem(cacheKey, JSON.stringify(cacheData));
        localStorage.setItem(cacheKey, JSON.stringify(cacheData));
        
        this.lastRefreshTime = new Date().toISOString();
        console.log('📋 Preloader - TBT Status Cached:', tbtDoc.Approval_Status_O_M__c, 
                   'at', this.lastRefreshTime, 'Offline:', this.isOffline);
        
        // 🟢 ENHANCED - Immediate event dispatch even in offline
        this.dispatchEvent(new CustomEvent('tbtstatusloaded', {
            detail: { 
                tbtDoc: cacheData, 
                userName,
                refreshTime: this.lastRefreshTime,
                isOffline: this.isOffline
            },
            bubbles: true,
            composed: true
        }));
    }

    @wire(getRecord, { recordId: USER_ID, fields: [USERNAME_FIELD] })
    wiredUser({ data, error }) {
        if (data) {
            this.userName = data.fields.Username.value;
            console.log('👤 Preloader - User loaded:', this.userName);
            
            // 🟢 Check network status first
            this.checkNetworkStatus();
            
            // 🟢 ALWAYS provide cached data immediately (works offline)
            this.provideCachedDataImmediately();
            
            // 🟢 Only start refresh if online
            if (!this.isOffline) {
                this.startMobileRefresh();
            }
        }
    }

    // 🟢 ADD - Network status checker
    checkNetworkStatus() {
        this.isOffline = !navigator.onLine;
        console.log('🌐 Preloader - Network status:', this.isOffline ? 'Offline' : 'Online');
        
        // Listen for network changes
        window.addEventListener('online', () => {
            this.isOffline = false;
            console.log('📡 Preloader - Now online, refreshing data');
            this.startMobileRefresh();
            setTimeout(() => this.forceTbtRefresh(), 2000);
        });
        
        window.addEventListener('offline', () => {
            this.isOffline = true;
            console.log('📴 Preloader - Now offline, using cached data');
            // Stop refresh intervals when offline
            if (this.refreshInterval) {
                clearInterval(this.refreshInterval);
            }
        });
    }

    // 🟢 ADD - Always provide cached data immediately (offline support)
    provideCachedDataImmediately() {
        if (!this.userName) return;
        
        const cacheKey = `tbtDoc_${this.userName}`;
        
        // 🟢 Check both storage locations
        let cachedData = sessionStorage.getItem(cacheKey);
        if (!cachedData) {
            cachedData = localStorage.getItem(cacheKey);
            if (cachedData) {
                // Restore to sessionStorage for faster access
                sessionStorage.setItem(cacheKey, cachedData);
            }
        }
        
        if (cachedData) {
            const tbtDoc = JSON.parse(cachedData);
            console.log('💾 Preloader - Immediate cached data:', tbtDoc.Approval_Status_O_M__c);
            
            // 🟢 Dispatch cached data immediately (works offline)
            this.dispatchEvent(new CustomEvent('tbtstatusloaded', {
                detail: { 
                    tbtDoc: tbtDoc, 
                    userName: this.userName,
                    refreshTime: tbtDoc.cachedAt,
                    isOffline: this.isOffline,
                    fromCache: true
                },
                bubbles: true,
                composed: true
            }));
        } else {
            console.log('⏳ Preloader - No cached data available yet');
            
            // 🟢 If offline and no cache, provide default data
            if (this.isOffline) {
                console.warn('⚠️ Preloader - Offline with no cache, using default');
                this.cacheTbtData({ Approval_Status_O_M__c: 'Pending' }, this.userName, 'offline_default');
            }
        }
    }

    startMobileRefresh() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
        
        // 🟢 Only refresh if online
        if (!this.isOffline) {
            this.refreshInterval = setInterval(() => {
                if (!this.isOffline) {
                    console.log('🔄 Mobile Preloader - Periodic refresh check');
                    this.forceTbtRefresh();
                }
            }, 30000);
        }
    }

    // 🟢 ENHANCED - Force refresh with offline check
    forceTbtRefresh() {
        if (!this.userName || this.isOffline) {
            console.log('📴 Preloader - Skipping refresh, offline mode');
            return;
        }
        
        console.log('🔄 Preloader - Force refreshing TBT data');
        
        // 🟢 Don't clear cache during refresh - keep it for offline fallback
        // The wire adapter will update the cache with fresh data
    }

    checkExistingCache() {
        if (!this.userName) return;
        
        const cacheKey = `tbtDoc_${this.userName}`;
        const cachedData = localStorage.getItem(cacheKey) || sessionStorage.getItem(cacheKey);
        
        if (cachedData) {
            const tbtDoc = JSON.parse(cachedData);
            console.log('💾 Preloader - Found cached data from:', tbtDoc.cachedAt);
            
            // 🟢 Only check staleness if online
            if (!this.isOffline) {
                const cacheAge = new Date() - new Date(tbtDoc.cachedAt);
                if (cacheAge > 120000) {
                    console.log('🕒 Cache is stale, forcing refresh');
                    this.forceTbtRefresh();
                    return;
                }
            }
            
            this.cacheTbtData(tbtDoc, this.userName, 'existing_cache');
        }
    }

    @wire(getListUi, {
        objectApiName: DOCUMENT_OBJECT,
        listViewApiName: 'O_M_TBT_Documents',
        pageSize: 200
    })
    wiredTbtDocuments({ data, error }) {
        if (data && this.userName) {
            const records = data.records.records;
            const match = records.find(
                rec => rec.fields.Submitted_Agent_Name__c.value === this.userName
            );

            if (match) {
                const tbtDoc = {
                    Approval_Status_O_M__c: match.fields.Approval_Status_O_M__c.value
                };
                this.cacheTbtData(tbtDoc, this.userName, 'wire_online');
            } else {
                console.warn('⚠️ Preloader - No TBT document found for user');
                this.cacheTbtData({ Approval_Status_O_M__c: 'Not Found' }, this.userName, 'wire_not_found');
            }
        } else if (error) {
            console.error('❌ Preloader - Error fetching TBT documents:', error);
            
            // 🟢 CRITICAL: Even on error, provide cached data (offline support)
            if (this.userName) {
                const cacheKey = `tbtDoc_${this.userName}`;
                const cachedData = sessionStorage.getItem(cacheKey) || localStorage.getItem(cacheKey);
                if (cachedData) {
                    const tbtDoc = JSON.parse(cachedData);
                    console.log('🔄 Preloader - Using cached data after error:', tbtDoc.Approval_Status_O_M__c);
                    this.cacheTbtData(tbtDoc, this.userName, 'error_fallback');
                } else {
                    console.warn('⚠️ Preloader - No cached data available after error');
                }
            }
        }
    }

    // 🟢 ENHANCED - Offline-aware event handling
    connectedCallback() {
        console.log('🔧 Preloader connected');
        this.isOffline = !navigator.onLine;
        
        // 🟢 Listen for manual refresh requests (only process if online)
        window.addEventListener('refreshTbtStatus', () => {
            if (!this.isOffline) {
                console.log('🔄 Preloader - Received manual refresh request');
                this.forceTbtRefresh();
            } else {
                console.log('📴 Preloader - Ignoring refresh request, offline');
            }
        });

        // 🟢 ADD - Provide cached data on component load (works offline)
        setTimeout(() => {
            if (this.userName) {
                this.provideCachedDataImmediately();
            }
        }, 500);
    }

    disconnectedCallback() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    }

    renderedCallback() {
        this.template.querySelector('div').style.display = 'none';
    }
}