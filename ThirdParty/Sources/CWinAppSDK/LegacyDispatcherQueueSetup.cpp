#include <dispatcherqueue.h>
#include <stdio.h>

extern "C"
void SetUpLegacyDispatcherQueueController() {
    printf(">>> SetUpLegacyDispatcherQueueController!\n");
    ABI::Windows::System::IDispatcherQueueController* controller;
    CreateDispatcherQueueController(
        DispatcherQueueOptions {
            sizeof(DispatcherQueueOptions),
            DQTYPE_THREAD_CURRENT,
            DQTAT_COM_STA
        },
        &controller
    );
}